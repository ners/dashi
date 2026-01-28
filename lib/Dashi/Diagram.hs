{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}

module Dashi.Diagram where

import Dashi.Prelude hiding (transform)
import Miso.Html.Property qualified as Html
import Miso.Html.Property qualified as Svg
import Miso.String qualified as MisoString
import Miso.Svg qualified
import Miso.Svg qualified as Svg
import Miso.Svg.Property qualified as Svg

--------------------------------------------------------------------------

class Shape s num | s -> num where
    boundingBox :: s -> Rect num
    transform :: (Point num -> Point num) -> s -> s

class (Shape s num) => ToSVG s num | s -> num where
    toSVG :: [Attribute action] -> s -> [View model action]

instance {-# OVERLAPS #-} (Num num, Ord num, Shape s num, Foldable f, Functor f) => Shape (f s) num where
    boundingBox = boundingBoxOfRects . fmap boundingBox
    transform = fmap . transform

instance {-# OVERLAPS #-} (Num num, Ord num, ToSVG s num, Foldable f, Functor f) => ToSVG (f s) num where
    toSVG = concatMap . toSVG

--------------------------------------------------------------------------

data Point num = Point {x :: num, y :: num}
    deriving stock (Generic, Eq, Show)

instance Shape (Point num) num where
    boundingBox p = Rect p p
    transform f = f

offsetPoint :: (num -> num) -> (num -> num) -> Point num -> Point num
offsetPoint fx fy = (#x %~ fx) . (#y %~ fy)

boundingBoxOfPoints1 :: forall f num. (Foldable f, Functor f, Ord num) => f (Point num) -> Rect num
boundingBoxOfPoints1 points =
    Rect
        { topLeft =
            Point
                { x = minimum xs
                , y = minimum ys
                }
        , bottomRight =
            Point
                { x = maximum xs
                , y = maximum ys
                }
        }
  where
    xs = x <$> points
    ys = y <$> points

boundingBoxOfPoints :: forall f num. (Foldable f, Functor f, Num num, Ord num) => f (Point num) -> Rect num
boundingBoxOfPoints (null -> True) = Rect (Point 0 0) (Point 0 0)
boundingBoxOfPoints points = boundingBoxOfPoints1 points

--------------------------------------------------------------------------

data Rect num = Rect {topLeft :: Point num, bottomRight :: Point num}
    deriving stock (Generic)

rectSize :: (Num num) => Rect num -> (num, num)
rectSize Rect{topLeft = Point{x = l, y = t}, bottomRight = Point{x = r, y = b}} = (r - l, b - t)

top :: Lens' (Rect num) num
top = #topLeft . #y

left :: Lens' (Rect num) num
left = #topLeft . #x

topRight :: Lens' (Rect num) (Point num)
topRight =
    lens
        (\Rect{topLeft = Point{y}, bottomRight = Point{x}} -> Point{..})
        (\r Point{..} -> r & top .~ y & right .~ x)

bottom :: Lens' (Rect num) num
bottom = #bottomRight . #y

right :: Lens' (Rect num) num
right = #bottomRight . #x

bottomLeft :: Lens' (Rect num) (Point num)
bottomLeft =
    lens
        (\Rect{topLeft = Point{x}, bottomRight = Point{y}} -> Point{..})
        (\r Point{..} -> r & bottom .~ y & left .~ x)

instance (Ord num) => Shape (Rect num) num where
    boundingBox = boundingBoxOfRects1 . Identity
    transform f Rect{..} = boundingBoxOfPoints1 [transform f topLeft, transform f bottomRight]

instance (Num num, Ord num, ToMisoString num) => ToSVG (Rect num) num where
    toSVG attrs r@Rect{topLeft = Point{..}} =
        pure
            . Svg.rect_
            $ Svg.x_ (toMisoString x)
            : Svg.y_ (toMisoString y)
            : Html.width_ (toMisoString width)
            : Html.height_ (toMisoString height)
            : attrs
      where
        (width, height) = rectSize r

boundingBoxOfRects1 :: (Foldable f, Ord num) => f (Rect num) -> Rect num
boundingBoxOfRects1 = boundingBoxOfPoints1 . concatMap \Rect{..} -> [topLeft, bottomRight]

boundingBoxOfRects :: (Foldable f, Num num, Ord num) => f (Rect num) -> Rect num
boundingBoxOfRects (null -> True) = boundingBoxOfPoints []
boundingBoxOfRects rects = boundingBoxOfRects1 rects

--------------------------------------------------------------------------

data Circle num = Circle {centre :: Point num, radius :: num}
    deriving stock (Generic)

instance (Num num) => Shape (Circle num) num where
    boundingBox Circle{..} =
        Rect
            { topLeft = offsetPoint (subtract radius) (subtract radius) centre
            , bottomRight = offsetPoint (+ radius) (+ radius) centre
            }
    transform f = #centre %~ f

instance (Num num, ToMisoString num) => ToSVG (Circle num) num where
    toSVG attrs Circle{centre = Point{..}, radius} =
        pure
            . Svg.rect_
            $ Svg.cx_ (toMisoString x)
            : Svg.cy_ (toMisoString y)
            : Svg.r_ (toMisoString radius)
            : attrs

--------------------------------------------------------------------------

data Line num = Line (Point num) (Point num)
    deriving stock (Generic)

instance (Num num, Ord num) => Shape (Line num) num where
    boundingBox (Line p1 p2) = boundingBoxOfPoints [p1, p2]
    transform f = #Line %~ (_1 %~ transform f) . (_2 %~ transform f)

instance (Num num, Ord num, ToMisoString num) => ToSVG (Line num) num where
    toSVG attrs (Line Point{x = x1, y = y1} Point{x = x2, y = y2}) =
        pure
            . Miso.Svg.line_
            $ Svg.x1_ (toMisoString x1)
            : Svg.y1_ (toMisoString y1)
            : Svg.x2_ (toMisoString x2)
            : Svg.y2_ (toMisoString y2)
            : attrs

--------------------------------------------------------------------------

newtype Polyline num = Polyline {points :: [Point num]}
    deriving stock (Generic)

instance (Num num, Ord num) => Shape (Polyline num) num where
    boundingBox Polyline{..} = boundingBoxOfPoints points
    transform f = #Polyline %~ fmap f

instance (Num num, Ord num, ToMisoString num) => ToSVG (Polyline num) num where
    toSVG attrs Polyline{..} =
        pure
            . Miso.Svg.polyline_
            $ Svg.points_ (MisoString.unwords $ mkPoint <$> points)
            : attrs
      where
        mkPoint :: Point num -> MisoString
        mkPoint Point{..} = MisoString.intercalate "," . fmap toMisoString $ [x, y]

--------------------------------------------------------------------------

newtype Polygon num = Polygon {points :: [Point num]}
    deriving stock (Generic)

instance (Num num, Ord num) => Shape (Polygon num) num where
    boundingBox Polygon{..} = boundingBoxOfPoints points
    transform f = #Polygon %~ fmap f

instance (Num num, Ord num, ToMisoString num) => ToSVG (Polygon num) num where
    toSVG attrs Polygon{..} =
        pure
            . Miso.Svg.polygon_
            $ Svg.points_ (MisoString.unwords . fmap mkPoint $ points)
            : attrs
      where
        mkPoint :: Point num -> MisoString
        mkPoint Point{..} = MisoString.intercalate "," . fmap toMisoString $ [x, y]

--------------------------------------------------------------------------

data TextAnchor
    = Start
    | Middle
    | End
    deriving stock (Eq)

instance ToMisoString TextAnchor where
    toMisoString Start = "start"
    toMisoString Middle = "middle"
    toMisoString End = "end"

data Text num = Text
    { position :: Point num
    , anchor :: TextAnchor
    , content :: MisoString
    }
    deriving stock (Generic)

instance Shape (Text num) num where
    boundingBox Text{..} = boundingBox position
    transform f = #position %~ transform f

instance (ToMisoString num) => ToSVG (Text num) num where
    toSVG attrs Text{position = Point{..}, ..} =
        pure
            . Svg.text_
                ( Svg.x_ (toMisoString x)
                    : Svg.y_ (toMisoString y)
                    : Svg.textAnchor_ (toMisoString anchor)
                    : attrs
                )
            . pure
            . text
            $ content

--------------------------------------------------------------------------

data SomeShape num = forall s. (Shape s num, ToSVG s num) => Shape s

instance Shape (SomeShape num) num where
    boundingBox (Shape s) = boundingBox s
    transform f (Shape s) = Shape $ transform f s

instance ToSVG (SomeShape num) num where
    toSVG attrs (Shape s) = toSVG attrs s

boundingBoxOfShapes :: (Foldable f, Functor f, Num num, Ord num) => f (SomeShape num) -> Rect num
boundingBoxOfShapes = boundingBoxOfRects . fmap boundingBox

--------------------------------------------------------------------------

svg
    :: ( Foldable t
       , Functor t
       , Fractional num
       , Ord num
       , ToMisoString num
       )
    => Rect num
    -> [Attribute action]
    -> t (SomeShape num)
    -> View model action
svg viewBox attrs shapes =
    Svg.svg_
        ( let
            Point{..} = topLeft viewBox
            (width, height) = rectSize viewBox
           in
            Svg.width_ (toMisoString width)
                : Svg.height_ (toMisoString height)
                : Svg.viewBox_ (MisoString.unwords . fmap toMisoString $ [x, y, width, height])
                : attrs
        )
        . concatMap (toSVG [] . translateDomain viewBox domain)
        $ shapes
  where
    domain = boundingBoxOfShapes shapes

translateDomain :: forall s num. (Shape s num, Eq num, Fractional num) => Rect num -> Rect num -> s -> s
translateDomain sup sub = transform $ translate #x . translate #y
  where
    minMax :: Lens' (Point num) num -> Rect num -> (num, num)
    minMax dim rect = (rect ^. #topLeft . dim, rect ^. #bottomRight . dim)
    translate :: Lens' (Point num) num -> Point num -> Point num
    translate dim =
        let
            (dMin, dMax) = minMax dim sub
            (vMin, vMax) = minMax dim sup
         in
            dim %~ \x ->
                if dMax == dMin
                    then vMin
                    else vMin + (x - dMin) * (vMax - vMin) / (dMax - dMin)

inDomain :: (Shape s num, Ord num, Fractional num) => Rect num -> s -> s
inDomain d s = translateDomain d (boundingBox s) s

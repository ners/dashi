module Graphics.Color.Uchu.Palette where

data Palette c cs e = Palette
    { gray :: c cs e
    , red :: c cs e
    , pink :: c cs e
    , purple :: c cs e
    , blue :: c cs e
    , green :: c cs e
    , yellow :: c cs e
    , orange :: c cs e
    }

convert :: (c' cs' e' -> c cs e) -> Palette c' cs' e' -> Palette c cs e
convert f Palette{..} =
    Palette
        { gray = f gray
        , red = f red
        , pink = f pink
        , purple = f purple
        , blue = f blue
        , green = f green
        , yellow = f yellow
        , orange = f orange
        }

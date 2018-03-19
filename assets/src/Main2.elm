port module Main exposing (..)

import Canvas exposing (Canvas, DrawOp(..), Point, Size)
import Color exposing (Color)
import Color.Convert exposing (hexToColor)
import Html exposing (..)
import Html.Attributes exposing (class, classList, id, placeholder, src, style, type_, value)
import Html.Events exposing (..)
import Json.Decode exposing (Decoder, andThen, bool, decodeValue, field, float, index, int, list, map3, string)
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import MouseEvents exposing (MouseEvent)
import Result exposing (Result)


type alias Flags =
    { canvasWidth : Int
    , canvasHeight : Int
    }


stringToDrawColor : String -> Decoder DrawColor
stringToDrawColor str =
    let
        res =
            case str of
                "#e74c3c" ->
                    Red

                "#e67e22" ->
                    Orange

                "#f1c40f" ->
                    Yellow

                "#27ae60" ->
                    Green

                "#3498db" ->
                    Blue

                "#9b59b6" ->
                    Purple

                "#34495e" ->
                    Black

                "#16a085" ->
                    Teal

                "#f39c12" ->
                    Gold

                _ ->
                    Red
    in
    decode res


colorDecoder : Decoder DrawColor
colorDecoder =
    string |> andThen stringToDrawColor



--userDecoder : Decoder User
--userDecoder =
--decode User
--|> optional "name" string "Anonymous"
--|> optional "color" colorDecoder Red
--|> required "id" string


remoteDrawDecoder : Decoder ( Point, Point, DrawColor )
remoteDrawDecoder =
    map3 (,,) (index 0 pointDecoder) (index 1 pointDecoder) (index 2 colorDecoder)


pointDecoder : Decoder Point
pointDecoder =
    decode Point
        |> required "x" float
        |> required "y" float


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { remoteCanvas = Canvas.initialize (Size flags.canvasWidth flags.canvasHeight)
      }
    , Cmd.none
    )


type alias Model =
    { remoteCanvas : Canvas
    }


type DrawColor
    = Red
    | Orange
    | Yellow
    | Green
    | Blue
    | Purple
    | Teal
    | Black
    | Gold



-- MAIN --


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type DrawState
    = Drawing Point
    | Moving Point
    | NotDrawing


type Msg
    = DrawFromRemote (Result String ( Point, Point, DrawColor ))



-- PORTS --


port receiveDraw : (Json.Decode.Value -> msg) -> Sub msg



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd msg )
update message model =
    case message of
        DrawFromRemote (Ok ( p1, p2, color )) ->
            ( { model
                | remoteCanvas = drawLine color p1 p2 model.remoteCanvas
              }
            , Cmd.none
            )

        DrawFromRemote (Err msg) ->
            ( model
            , Cmd.none
            )



-- VIEW --


colors : List DrawColor
colors =
    [ Red
    , Orange
    , Yellow
    , Green
    , Blue
    , Purple
    , Black
    , Gold
    , Teal
    ]


getDrawColorName : DrawColor -> String
getDrawColorName color =
    case color of
        Red ->
            "Red"

        Orange ->
            "Orange"

        Yellow ->
            "Yellow"

        Green ->
            "Green"

        Blue ->
            "Blue"

        Purple ->
            "Purple"

        Black ->
            "Black"

        Teal ->
            "Teal"

        Gold ->
            "Gold"


drawColorToHex : DrawColor -> String
drawColorToHex color =
    case color of
        Red ->
            "#e74c3c"

        Orange ->
            "#e67e22"

        Yellow ->
            "#f1c40f"

        Green ->
            "#27ae60"

        Blue ->
            "#3498db"

        Purple ->
            "#9b59b6"

        Black ->
            "#34495e"

        Teal ->
            "#16a085"

        Gold ->
            "#f39c12"


view : Model -> Html Msg
view model =
    Canvas.toHtml [ style [] ] model.remoteCanvas



-- Subs --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receiveDraw (DrawFromRemote << decodeValue remoteDrawDecoder)
        ]



--Sub.none
-- HELPERS --


toPoint : MouseEvent -> Point
toPoint { targetPos, clientPos } =
    Point
        (toFloat (clientPos.x - targetPos.x))
        (toFloat (clientPos.y - targetPos.y))


drawColorToColor : DrawColor -> Color
drawColorToColor color =
    let
        res =
            color |> drawColorToHex |> hexToColor
    in
    case res of
        Ok color ->
            color

        _ ->
            Color.black


drawLine : DrawColor -> Point -> Point -> Canvas -> Canvas
drawLine color pt0 pt1 =
    [ BeginPath
    , LineWidth 4
    , LineCap "round"
    , MoveTo pt0
    , LineTo pt1
    , StrokeStyle (drawColorToColor color)
    , Stroke
    ]
        |> Canvas.batch
        |> Canvas.draw

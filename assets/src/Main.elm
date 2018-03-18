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


userDecoder : Decoder User
userDecoder =
    decode User
        |> optional "name" string "Anonymous"
        |> optional "color" colorDecoder Red
        |> required "id" string


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
    ( { canvas = Canvas.initialize (Size flags.canvasWidth flags.canvasHeight)
      , remoteCanvas = Canvas.initialize (Size flags.canvasWidth flags.canvasHeight)
      , drawState = NotDrawing
      , userName = ""
      , userEmail = ""
      , showUserForm = False
      , color = Red
      , users = []
      }
    , Cmd.none
    )


type alias Model =
    { canvas : Canvas
    , remoteCanvas : Canvas
    , drawState : DrawState
    , userName : String
    , userEmail : String
    , showUserForm : Bool
    , color : DrawColor
    , users : List User
    }


type alias User =
    { name : String
    , color : DrawColor
    , id : String
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
    = MouseDown MouseEvent
    | MouseUp MouseEvent
    | Move MouseEvent
    | UpdateUserName String
    | SaveUserName
    | UpdateDrawColor DrawColor
    | ShowUserForm
    | UpdatePresence (Result String (List User))
    | DrawFromRemote (Result String ( Point, Point, DrawColor ))



-- PORTS --


port presenceUpdate : (Json.Decode.Value -> msg) -> Sub msg


port updateColor : String -> Cmd msg


port updateName : String -> Cmd msg


port handleDraw : ( Point, Point, String ) -> Cmd msg


port receiveDraw : (Json.Decode.Value -> msg) -> Sub msg



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd msg )
update message model =
    case message of
        UpdatePresence (Ok users) ->
            let
                foo =
                    Debug.log (toString users)
            in
            ( { model | users = users }, Cmd.none )

        UpdatePresence (Err msg) ->
            let
                foo =
                    Debug.log msg
            in
            ( model, Cmd.none )

        ShowUserForm ->
            ( { model | showUserForm = True }, Cmd.none )

        UpdateDrawColor color ->
            ( { model | color = color }, updateColor (color |> drawColorToHex) )

        SaveUserName ->
            ( { model | showUserForm = False }, updateName model.userName )

        UpdateUserName a ->
            ( { model | userName = a }, Cmd.none )

        DrawFromRemote (Ok ( p1, p2, color )) ->
            ( { model
                | remoteCanvas = drawLine color p1 p2 model.remoteCanvas
                , drawState = NotDrawing
              }
            , Cmd.none
            )

        DrawFromRemote (Err msg) ->
            ( model
            , Cmd.none
            )

        MouseUp mouseEvent ->
            case model.drawState of
                NotDrawing ->
                    ( { model
                        | canvas = model.canvas
                        , drawState = NotDrawing
                      }
                    , Cmd.none
                    )

                Drawing p1 ->
                    ( { model
                        | canvas = drawLine model.color p1 (toPoint mouseEvent) model.canvas
                        , drawState = NotDrawing
                      }
                    , Cmd.none
                    )

                Moving p1 ->
                    ( { model
                        | canvas = drawLine model.color p1 (toPoint mouseEvent) model.canvas
                        , drawState = NotDrawing
                      }
                    , Cmd.none
                    )

        MouseDown mouseEvent ->
            ( { model
                | canvas = model.canvas
                , drawState = Drawing (toPoint mouseEvent)
              }
            , Cmd.none
            )

        Move mouseEvent ->
            case model.drawState of
                Drawing p1 ->
                    ( { model
                        | canvas = drawLine model.color p1 (toPoint mouseEvent) model.canvas
                        , drawState = Moving (toPoint mouseEvent)
                      }
                    , handleDraw ( p1, toPoint mouseEvent, model.color |> drawColorToHex )
                    )

                Moving p1 ->
                    ( { model
                        | canvas = drawLine model.color p1 (toPoint mouseEvent) model.canvas
                        , drawState = Moving (toPoint mouseEvent)
                      }
                      --, Cmd.none
                    , handleDraw ( p1, toPoint mouseEvent, model.color |> drawColorToHex )
                    )

                NotDrawing ->
                    ( model, Cmd.none )



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


viewOnlineUsers : Model -> Html Msg
viewOnlineUsers model =
    let
        render =
            \user ->
                div
                    [ class "online-user"
                    , style
                        [ ( "background", user.color |> drawColorToHex )
                        ]
                    ]
                    [ String.slice 0 1 user.name |> text ]
    in
    div [ class "online-users" ]
        (List.map
            render
            model.users
        )


viewDrawColorBlock : Model -> DrawColor -> Html Msg
viewDrawColorBlock model color =
    div [ classList [ ( "color-block", True ), ( "checked", color == model.color ) ], style [ ( "background", color |> drawColorToHex ) ], onClick (UpdateDrawColor color) ] []


viewDrawColorSwatch : Model -> Html Msg
viewDrawColorSwatch model =
    let
        viewDrawColorBlockWithModel =
            viewDrawColorBlock model

        colorBlocks =
            List.map viewDrawColorBlockWithModel colors
    in
    div []
        [ div [ class "color-blocks" ] colorBlocks
        ]


viewUser : Model -> Html Msg
viewUser model =
    case ( model.showUserForm, model.userName ) of
        ( True, _ ) ->
            div [ class "user" ]
                [ Html.form [ class "user-form", onSubmit SaveUserName ]
                    [ div [ class "control" ]
                        [ input [ class "text", type_ "text", placeholder "Name", onInput UpdateUserName, value model.userName, onBlur SaveUserName ] []
                        ]
                    ]
                ]

        ( False, "" ) ->
            div [ class "user" ]
                [ a [ onClick ShowUserForm ] [ text "Set name" ]
                ]

        ( False, _ ) ->
            div [ class "user" ]
                [ div [ onClick ShowUserForm ] [ text model.userName ]
                ]


view : Model -> Html Msg
view model =
    div [ class "main" ]
        [ div [ class "sidebar" ]
            [ viewUser model
            , viewDrawColorSwatch model
            ]
        , div [ class "content" ]
            [ Canvas.toHtml [ style [ ( "position", "absolute" ) ] ] model.remoteCanvas
            , Canvas.toHtml [ style [ ( "position", "absolute" ) ], MouseEvents.onMouseDown MouseDown, MouseEvents.onMouseUp MouseUp, MouseEvents.onMouseMove Move ] model.canvas
            , viewOnlineUsers model
            ]
        ]



-- Subs --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ presenceUpdate (UpdatePresence << decodeValue (list userDecoder))
        , receiveDraw (DrawFromRemote << decodeValue remoteDrawDecoder)
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

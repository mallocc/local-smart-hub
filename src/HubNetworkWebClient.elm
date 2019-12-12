module HubNetworkWebClient exposing (main)

import Browser
import Css exposing (..)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Decoder, int, string, float)
import Json.Decode.Pipeline exposing (required, optional, hardcoded)
import Time



bigButton : List (Attribute msg) -> List (Html msg) -> Html msg
bigButton =
    styled Html.Styled.button
        [ Css.width (px 300)
        , backgroundColor (hex "#397cd5")
        , color (hex "#fff")
        , padding2 (px 14) (px 20)
        , marginTop (px 10)
        , border (px 0)
        , borderRadius (px 4)
        , fontSize (px 16)
        , textAlign center
        ]


bigButtonRefreshing : List (Attribute msg) -> List (Html msg) -> Html msg
bigButtonRefreshing =
    styled bigButton
        [ backgroundColor (hex "#999955") ]


colorButton : List (Attribute msg) -> List (Html msg) -> Html msg
colorButton =
    styled Html.Styled.button
        [ Css.width (px 50)
                , backgroundColor (hex "#397cd5")
        , color (hex "#fff")
        , margin (px 5)
        , border (px 0)
        , borderRadius (px 4)
        , fontSize (px 15)
        ]

smallButton : List (Attribute msg) -> List (Html msg) -> Html msg
smallButton =
    styled Html.Styled.button
        [ Css.width (px 150)
        , color (hex "#fff")
        , padding2 (px 14) (px 20)
        , margin (px 5)
        , marginLeft (px 50)
        , border (px 0)
        , borderRadius (px 4)
        , fontSize (px 15)
        , boxShadow4 (px 1) (px 2) (px 3) (hex "#888888")
        ]


smallButtonOn : List (Attribute msg) -> List (Html msg) -> Html msg
smallButtonOn =
    styled smallButton
        [ backgroundColor (hex "#228866") ]


smallButtonWaiting : List (Attribute msg) -> List (Html msg) -> Html msg
smallButtonWaiting =
    styled smallButton
        [ backgroundColor (hex "#999955") ]


smallButtonOff : List (Attribute msg) -> List (Html msg) -> Html msg
smallButtonOff =
    styled smallButton
        [ backgroundColor (hex "#114433") ]


type alias RGB =
    { red : Int
    , green : Int
    , blue : Int
    }

nullRGB : RGB
nullRGB =
    { red = -1
    , green = -1
    , blue = -1
    }


type alias Device =
    { name : String
    , status : String
    , commandUrl : String
    , rgb : RGB
    }


type alias Devices =
    List Device


type alias Model =
    { devices : Devices
    , waitingForHubStatus : Bool
    , time : Time.Posix
    , errorMessage : Maybe String
    }


viewError : String -> Html Msg
viewError errorMessage =
    let
        errorHeading =
            "Couldn't fetch data at this time."
    in
    div []
        [ h3 [] [ text errorHeading ]
        , text ("Error: " ++ errorMessage)
        ]


viewTableHeader : Html Msg
viewTableHeader =
    tr []
        [ th []
            [ text "Name" ]
        , th []
            [ text "Status" ]
        , th []
            [ text "RGB" ]
        ]


rgbTableHeader : Html Msg
rgbTableHeader =
    tr []
        [ th []
            [ text "R" ]
        , th []
            [ text "G" ]
        , th []
            [ text "B" ]
        ]

viewDevice : Device -> Html Msg
viewDevice device =
    tr []
        [ td []
            [ text device.name ]
        , td []
            [ if device.status == "ON" then
                smallButtonOn [ onClick (RequestDeviceStatus device) ] [ text "Switch Off" ]

              else if device.status == "WAITING" then
                smallButtonWaiting [ onClick (RequestDeviceStatus device) ] [ text "Commanding..." ]

              else
                smallButtonOff [ onClick (RequestDeviceStatus device) ] [ text "Switch On" ]
            ]
            , if device.rgb.red >= 0 then
                td [ css [ backgroundColor (rgb 
                        device.rgb.red
                        device.rgb.green
                        device.rgb.blue) ] ] 
                    [
                         tr [] 
                            [
                                  td []
                                    [ colorButton [ onClick (RequestDeviceColor device "red" "up") ] [ text "+R" ]
                                    ,colorButton [ onClick (RequestDeviceColor device "red" "down") ] [ text "-R" ]
                                    ]
                                , td []
                                    [ colorButton [ onClick (RequestDeviceColor device "green" "up") ] [ text "+G" ]
                                    ,colorButton [ onClick (RequestDeviceColor device "green" "down") ] [ text "-G" ]
                                    ]
                                , td []
                                    [ colorButton [ onClick (RequestDeviceColor device "blue" "up") ] [ text "+B" ]
                                    ,colorButton [ onClick (RequestDeviceColor device "blue" "down") ] [ text "-B" ]
                                    ]
                            ]
                    ]

            else
                td [] []
        ]


viewStatus : Devices -> Html Msg
viewStatus status =
    div
        [ style "backgroundColor" "#f2f2f2"
        , style "borderRadius" "5px"
        , style "padding" "20px"
        , css [ boxShadow4 (px 1) (px 2) (px 3) (hex "#888888") ]
        ]
        [ h2 [ css [ textAlign center ] ] [ text "Device Status" ]
        , Html.Styled.table []
            ([ viewTableHeader ] ++ List.map viewDevice status)
        ]


viewStatusOrError : Model -> Html Msg
viewStatusOrError model =
    case model.errorMessage of
        Just message ->
            viewError message

        Nothing ->
            viewStatus model.devices


view : Model -> Html Msg
view model =
    div
        [ style "width" "500px"
        , css [ margin2 (px 20) auto ]
        , css [ fontFamilies [ "Verdana", "Arial" ] ]
        ]
        [ h1
            [ style "text-align" "center"
            , css [ margin2 (px 20) auto ]
            ]
            [ text "Local Smart Network" ]
        , viewStatusOrError model
        -- , if model.waitingForHubStatus then
        --     bigButtonRefreshing
        --         [ onClick RequestHubStatus ]
        --         [ text "Refreshing..." ]

        --   else
        --     bigButton
        --         [ onClick RequestHubStatus ]
        --         [ text "Refresh" ]
        ]


buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later."

        Http.NetworkError ->
            "Unable to reach server."

        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ String.fromInt statusCode

        Http.BadBody message ->
            message


urlHub : String
urlHub =
    -- "http://192.168.1.94:8000"
    "http://localhost:8000"


rgbDecoder : Decoder RGB
rgbDecoder =
    Decode.succeed  RGB
        |> Json.Decode.Pipeline.required "red" Decode.int
        |> Json.Decode.Pipeline.required "green" Decode.int
        |> Json.Decode.Pipeline.required "blue" Decode.int


deviceDecoder : Decoder Device
deviceDecoder =
    Decode.succeed Device
        |> Json.Decode.Pipeline.required "name" string
        |> Json.Decode.Pipeline.required "status" string
        |> Json.Decode.Pipeline.required "url" string
        |> Json.Decode.Pipeline.optional "rgb" rgbDecoder nullRGB


statusDecoder : Decoder Devices
statusDecoder =
    Decode.map identity (Decode.field "devices" (Decode.list deviceDecoder))


getStatus : Cmd Msg
getStatus =
    Http.get
        { url = urlHub ++ "/refresh"
        , expect = Http.expectJson DataReceived statusDecoder
        }


getDeviceStatus : String -> Cmd Msg
getDeviceStatus subUrl =
    Http.get
        { url = urlHub ++ subUrl
        , expect = Http.expectJson DataReceived statusDecoder
        }


requestColor : Device -> String -> String -> Cmd Msg
requestColor device color direction =
    Http.get
        { url = urlHub ++ device.commandUrl ++ "/rgb/" ++ color ++ "/" ++ direction
        , expect = Http.expectJson DataReceived statusDecoder
        }


type Msg
    = RequestHubStatus
    | RequestDeviceStatus Device
    | RequestDeviceColor Device String String
    | DataReceived (Result Http.Error Devices)
    | Tick Time.Posix


setWaiting device =
    { device | status = "WAITING" }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RequestHubStatus ->
            ( { model | waitingForHubStatus = True }, getStatus )

        RequestDeviceStatus device ->
            let
                devices =
                    model.devices

                newDevices =
                    List.map
                        (\x ->
                            if x.name /= device.name then
                                x

                            else
                                setWaiting device
                        )
                        devices
            in
            ( { model
                | devices = newDevices
              }
            , getDeviceStatus device.commandUrl
            )

        RequestDeviceColor device color dircetion ->
            ( model, requestColor device color dircetion )
            
        DataReceived (Ok status) ->
            ( { model
                | devices = status
                , waitingForHubStatus = False
              }
            , Cmd.none
            )

        DataReceived (Err httpError) ->
            ( { model
                | errorMessage = Just (buildErrorMessage httpError)
              }
            , Cmd.none
            )

        Tick newTime ->
            ( { model | time = newTime }
            , getStatus
            )


subscriptions : Model -> Sub Msg
subscriptions model =
  Time.every 1000 Tick


init : () -> ( Model, Cmd Msg )
init _ =
    ( { devices = []
      , waitingForHubStatus = True
      , time = Time.millisToPosix 0
      , errorMessage = Nothing
      }
    , getStatus
    )


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view >> toUnstyled
        , update = update
        , subscriptions = subscriptions
        }

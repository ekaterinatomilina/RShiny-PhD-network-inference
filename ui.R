# Definition de la partie UI 
ui <- fluidPage(

    # Titre de l application
    titlePanel("Application de Dev - SK8-Team"),

    # affiche une image
    mainPanel(
        imageOutput("SK8Image")
    ),
    div(
        class="footer",
        includeHTML("footer.html"),
        br(),
        HTML(paste0('<center style="font-size:12px"> Version ',{Sys.getenv("APP_VERSION")},' </center>'))
    )
)


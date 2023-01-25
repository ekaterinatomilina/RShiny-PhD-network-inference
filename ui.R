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
        HTML(paste0('<div style="bottom:0;font-size:12px;position: absolute;right: 0;"> Version ',{Sys.getenv("APP_VERSION")},' </div>'))
    )
)


# Defini la partie server
server <- function(input, output, session) {

    output$SK8Image <- renderImage({
	    list(src= normalizePath(file.path("www/images","SK8.png")),
		 contentType = 'image/png',
		 width = 200,
		 alt = "Logo SK8")
    }, deleteFile = FALSE)
}


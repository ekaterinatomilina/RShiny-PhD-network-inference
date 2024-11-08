ui <- fluidPage(theme=bs_theme(version=5,bootswatch = "minty"),
                useShinyjs(),
                # Application title
                titlePanel("Gaussian copula correlation network inference"),
                card(tags$div("This application enables the user to perform network inference on heterogeneous variables by assuming a Gaussian copula structure.
    Even if the data set is high dimensional, the computational cost is reduced by using a pairwise likelihood. The calculations are performed via the ",
                              tags$a(href="https://cran.r-project.org/web/packages/heterocop/index.html","heterocop"),
                              "R package.")),
                sidebarLayout(
                  sidebarPanel(
                    card(strong("Load your own data"), fileInput("dataset","Please use .csv format, with variables separated by a semi colon",accept=".csv"),
                         em("The application can automatically detect your variable type (continuous or  discrete), but we do not guarantee full reliability. 
                             You can check the box below to specify the number of variables of each type yourself. In this case, note that the 
                             columns of your .csv have to contain all continuous variables first.")
                    )
                    ,
                    card("", checkboxInput("specify","Specify the number of each variables",value=FALSE),
                         conditionalPanel(
                           condition = "input.specify",
                           numericInput('cont', 'How many continuous variables ?', value=0),
                           numericInput('disc', 'How many discrete variables ?', value=0)
                         )
                    )
                  ),
                  mainPanel(
                    accordion(
                      accordion_panel("Dataset",
                                      checkboxInput("subset","Display only a subset of your data",value=FALSE),
                                      conditionalPanel( condition = "input.subset",
                                                        card("Which rows and columns do you want to display?",
                                                             fluidRow("Columns"),
                                                             fluidRow(column(5,numericInput('colmin',label="from",value=1,min=1)),
                                                                      column(5,numericInput('colmax',label="to",value=1,min=1))),
                                                             "Rows",
                                                             fluidRow(column(5,numericInput('rowmin',label="from",value=1,min=1)),
                                                                      column(5,numericInput('rowmax',label = "to",value=1,min=1))))
                                      ),
                                      card("",tableOutput("contents"))
                                      ,downloadButton("download_data", label="Download the selected dataset")),
                      accordion_panel("Correlation matrix",
                                      checkboxInput("subsetmat","Display only a subset of your correlation matrix",value=FALSE),
                                      conditionalPanel( condition = "input.subsetmat",
                                                        card("Which rows and columns do you want to display?",
                                                             fluidRow("Columns"),
                                                             fluidRow(column(5,numericInput('matcmin',label="from",value=1,min=1)),
                                                                      column(5,numericInput('matcmax',label="to",value=1,min=1))),
                                                             "Rows",
                                                             fluidRow(column(5,numericInput('matrmin',label="from",value=1,min=1)),
                                                                      column(5,numericInput('matrmax',label = "to",value=1,min=1))))
                                      ),
                                      card(textOutput("progress"),
                                           tableOutput("Mhat"))
                                      ,downloadButton("download_matrix", label="Download the correlation matrix of the copula")),
                      accordion_panel("Corrplot",
                                      selectInput("corrplot_type",label="Customize your corrplot",choices=list("circle", "square", "ellipse", "number", "shade", "color", "pie")),
                                      plotOutput("corr_plot"),
                                      downloadButton("download_corrplot", label="Download the corrplot")),
                      accordion_panel("Graphical representation",
                                      em("The graph corresponding to the correlation matrix is shown below. An edge is present between two vertices if their correlation coefficient is greater than the threshold defined below. The colors correspond to the variable type (discrete or continuous), but more coloring options are available in the Customize your graph section."),
                                      numericInput("T_hat",label = "Enter the correlation threshold", value = 0.5, min = 0,step=0.1),
                                      checkboxInput("custom","Customize your graph",value=FALSE),
                                      conditionalPanel(condition="input.custom",
                                                       fluidRow(column(5,colourpicker::colourInput("colcont",label="Select the color for continuous variables",value="goldenrod1")),
                                                                column(5,colourpicker::colourInput("coldisc",label="Select the color for discrete variables",value="lightskyblue"))),
                                                       checkboxInput("other_group","I want to add more groups of variables",value=F),
                                                       conditionalPanel(condition="input.other_group",
                                                                        numericInput("nbgps","Enter the number of groups",value=2,min=1),
                                                                        fluidRow(column(4,uiOutput("groups1")),column(4,uiOutput("groups2")),column(4,uiOutput("groups3")))
                                                       )),
                                      fluidRow(plotOutput("plot"),
                                               downloadButton("download_plot", label="Download the graph"))
                      )
                    )
                  )
                )
)


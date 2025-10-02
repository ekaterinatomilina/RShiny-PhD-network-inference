ui <- fluidPage(title="Gaussian copula network inference",
theme=bs_theme(version=5, bootswatch = "lux"),
                useShinyjs(),
                add_busy_spinner(spin = "flower",color="blue",position="bottom-right"),
                titlePanel(h1("Gaussian copula network inference",align="center")),
                
                card(tags$div("This application enables the user to perform network inference on heterogeneous variables by assuming a Gaussian copula structure.
    Even if the data set is high dimensional, the computational cost is reduced by using a pairwise likelihood. The calculations are performed via the ",
                              tags$a(href="https://cran.r-project.org/web/packages/heterocop/index.html","heterocop"),
                              "R package.")),
                navlistPanel(
                  id="tabset",
                "Dataset",
                tabPanel("Load your data",
                fluidRow(
                      card("LOAD YOUR DATASET", fileInput("dataset","Please use .csv format.",accept=".csv"),
                           em("The application can automatically detect your variable type (continuous or  discrete), but we do not guarantee full reliability. 
                                 You can check the box below to specify the number of variables of each type yourself. In this case, note that the 
                                 columns of your .csv have to contain all continuous variables first.")
                      ,checkboxInput("specify","Specify the variable type",value=FALSE),
                           conditionalPanel(
                             condition = "input.specify",
                             numericInput('cont', 'How many continuous variables ?', value=0),
                             numericInput('disc', 'How many discrete variables ?', value=0)
                           )
                      ),
                      card(strong("DATASET"),
                                       card("",tableOutput("contents")),
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
                           
                           downloadButton("download_data", label="Download the selected dataset"))
                    )
                  ),
                "Correlation network",
                tabPanel("About",
                         tags$div("The methodology for estimating the correlation matrix of the Gaussian copula is presented in the following preprint. Supplementary material is available on ",
                                  tags$a(href="https://hal.inrae.fr/hal-04847648","hal inrae"),
                                  "."),
                         tags$div(
                           style = "text-align: center;margin-top: 20px;",
                           tags$iframe(style = "height:500px; width:60%", src = "main.pdf"))
                         ),
                tabPanel("Correlation matrix",
                fluidRow(
                  column(width=12,
                         card(
                      accordion(
                          accordion_panel("Correlation matrix",
                                          tableOutput("Mhat"),textOutput("progress")),
                          card(checkboxInput("subsetmat","Display only a subset of your correlation matrix",value=FALSE),
                                          conditionalPanel( condition = "input.subsetmat",
                                                            card("Which rows and columns do you want to display?",
                                                                 fluidRow("Columns"),
                                                                 fluidRow(column(5,numericInput('matcmin',label="from",value=1,min=1)),
                                                                          column(5,numericInput('matcmax',label="to",value=1,min=1))),
                                                                 "Rows",
                                                                 fluidRow(column(5,numericInput('matrmin',label="from",value=1,min=1)),
                                                                          column(5,numericInput('matrmax',label = "to",value=1,min=1))))
                                          ),
                                          downloadButton("download_matrix", label="Download the correlation matrix of the copula")
                                            ),
                          accordion_panel("Corrplot",
                                          selectInput("corrplot_type",label="Customize your corrplot",choices=list("circle", "square", "ellipse", "number", "shade", "color", "pie")),
                                          plotOutput("corr_plot"),
                                          downloadButton("download_corrplot", label="Download the corrplot")
                                        )))))),
                tabPanel("Correlation graph",
                         fluidRow(column(width=12,
                         card(em("The graph corresponding to the correlation matrix is shown below. An edge is present between two vertices if the absolute value of their correlation coefficient is greater than the threshold specified below (default 0.5)."),
                                          numericInput("T_hat",label = "Enter the correlation threshold", value = 0.5, min = 0,step=0.1),
                                          em("The default colors correspond to the variable type (discrete or continuous), but more coloring options are available by ticking the box below."),
                                          checkboxInput("custom","Customize your graph",value=FALSE),
                                            conditionalPanel(condition="input.custom",
                                                             fluidRow(column(5,colourpicker::colourInput("colcont",label="Select the color for continuous variables",value="goldenrod1")),
                                                                      column(5,colourpicker::colourInput("coldisc",label="Select the color for discrete variables",value="lightskyblue"))),
                                                             checkboxInput("other_group","I want to add more groups of variables",value=F),
                                                             conditionalPanel(condition="input.other_group",
                                                                              numericInput("nbgps","Enter the number of groups",value=2,min=1),
                                                                              fluidRow(column(4,uiOutput("groups1")),column(4,uiOutput("groups2")),column(4,uiOutput("groups3")))
                                                             )
                                                             ),
                                        fluidRow(plotOutput("plot"),
                                                 downloadButton("download_plot", label="Download the graph"))
                                        )
                        
                  )
                  )
                  )
                ,
                "Conditional correlation network",
                tabPanel("About",
                         tags$div("The methodology for estimating the precision matrix of the Gaussian copula is presented in the following preprint. Supplementary material is available on ",
                                  tags$a(href="https://hal.inrae.fr/hal-05173829v1","hal inrae"),
                                  "."),
                         tags$div(
                           style = "text-align: center;margin-top: 20px;",
                           tags$iframe(style = "height:500px; width:60%", src = "main2.pdf"))
                ),
                tabPanel("Precision matrix",
                         fluidRow(
                column(width=12,
                           card(
                             accordion(
                               accordion_panel("Conditional covariance matrix",
                                               conditionalPanel(condition="input.lambdagrid==false",numericInput("lambda",label = "Enter the penalization parameter", value = 0.1, min = 0,step=0.01)),
                                               checkboxInput("lambdagrid","Optimal lambda selection",value=FALSE),
                                               conditionalPanel(condition="input.lambdagrid",
                                               card(fluidRow(
                                                column(4, numericInput("lambdamin",label = "Enter the smallest value of lambda", value = 0.3, min = 0.01,step=0.01)),
                                                column(4, numericInput("lambdamax",label = "Enter the highest value of lambda", value = 0.35, min = 0.01,step=0.01)),
                                                       column(4, numericInput("lambdastep",label = "Enter the step", value = 0.01, min = 0.001,step=0.001)))
                                                )),
                                               tableOutput("OMhat"),
                                               checkboxInput("subsetmatcov","Display only a subset of your precision matrix",value=FALSE),
                                               conditionalPanel( condition = "input.subsetmatcov",
                                                                 card("Which rows and columns do you want to display?",
                                                                      fluidRow("Columns"),
                                                                      fluidRow(column(5,numericInput('matcmin2',label="from",value=1,min=1)),
                                                                               column(5,numericInput('matcmax2',label="to",value=1,min=1))),
                                                                      "Rows",
                                                                      fluidRow(column(5,numericInput('matrmin2',label="from",value=1,min=1)),
                                                                               column(5,numericInput('matrmax2',label = "to",value=1,min=1))))
                                               )
                                               ,downloadButton("download_matrix2", label="Download the conditional covariance matrix of the copula"))
                               ,accordion_panel("Optimal lambda value",
                                                conditionalPanel(condition="input.lambdagrid==false",
                                                "Please tick the Optimal lambda selection box"),
                                 conditionalPanel(condition="input.lambdagrid==true",
                                                card(plotOutput("crit_lamb"))
                                                 ,downloadButton("download_crit", label="Download the HBIC plot")
                                 ))
                               ))))),
                tabPanel("Conditional correlation graph",
                         fluidRow(column(width=12,
                                         em("The graph corresponding to the conditional covariance matrix is shown below. An edge is present between two vertices if their conditional covariance coefficient is non null. The default colors correspond to the variable type (discrete or continuous), but more coloring options are available by ticking the box below."),
                                              checkboxInput("custom2","Customize your graph",value=FALSE),
                                               conditionalPanel(condition="input.custom2",
                                                                fluidRow(column(5,colourpicker::colourInput("colcont2",label="Select the color for continuous variables",value="goldenrod1")),
                                                                         column(5,colourpicker::colourInput("coldisc2",label="Select the color for discrete variables",value="lightskyblue"))),
                                                                checkboxInput("other_group2","I want to add more groups of variables",value=F),
                                                                conditionalPanel(condition="input.other_group2",
                                                                                 numericInput("nbgps2","Enter the number of groups",value=2,min=1),
                                                                                 fluidRow(column(4,uiOutput("groups21")),column(4,uiOutput("groups22")),column(4,uiOutput("groups23")))
                                                                )
                                               ),
                                               fluidRow(plotOutput("plot2"),
                                                        downloadButton("download_plot2", label="Download the graph"))
                           )
                  )
                )
),
tags$footer(
  style = "
      position:fixed;
      bottom:0;
      left:0;
      width:100%;
      background:#f8f8f8;
      border-top:1px solid #ddd;
      text-align:center;
      padding:8px;
      font-size:12px;
      color:#555;
      z-index:1000;
    ",
  HTML('Propulsé par <a href="https://sk8.inrae.fr" target="_blank">SK8</a> depuis 2021 -
          <a href="https://sk8.inrae.fr" target="_blank">
            <img src="images/SK8.png" style="vertical-align:middle;height:25px;"/>
          </a>')
)

)



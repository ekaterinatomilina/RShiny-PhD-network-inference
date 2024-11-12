server <- function(input, output,session) {
  # Estimation tab
  dataframe <- reactive({
    file <- input$dataset
    ext <- tools::file_ext(file$datapath)
    req(file)
    validate(need(ext == "csv", "Please upload a csv file"))
    read.csv2(file$datapath, header = TRUE,sep=";")
  })
  
  trunc_data <- reactive({
    if(sum(is.na(dataframe()))==0){
    if(!input$subset){
      dataframe()
    }else{
      dataframe()[input$rowmin:input$rowmax,input$colmin:input$colmax]
    }
    }else{
      print("Your data contains NAs")
    }
  })
  
  output$contents <- renderTable({
    trunc_data()
  })
  
  output$download_data <- downloadHandler(filename = "new_dataset.csv",
                                          content = function(file){
                                            write.csv2(trunc_data(),file)
                                          }
  )
  
  type_vec <- reactive({
    validate(need(sum(is.na(dataframe()))==0,""))
    if(!input$specify){
      type <- c()
      for(i in 1:dim(dataframe())[2]){
        if(sum(dataframe()[,i]%%1)==0){
          type <- c(type,"D")
        }else{
          type <- c(type,"C")
        }
      }
    }else{
      type <- c(rep("C",input$cont),rep("D",input$disc))
    }
    return(type)
  })
  
  
  PROGRESS_FILE <- "progress.txt"
  
  task <- ExtendedTask$new(function(data,type){
    mirai({
      sink(PROGRESS_FILE,type="output")
      on.exit(sink())
      rho_estim(data,type,parallel=TRUE)
    }, rho_estim=rho_estim,data=data,type=type,PROGRESS_FILE = PROGRESS_FILE)
  })
  observeEvent(input$dataset, task$invoke(dataframe(),type_vec()))
  
  progress <- reactiveFileReader(100, session, PROGRESS_FILE, function(path) {
    if (file.exists(path)){
      print(path)
      print(readLines(path, -1, warn = FALSE))}
    else{print("")}
  })
  output$progress <- renderText({ progress() })
  
  observeEvent(task$result(), unlink(PROGRESS_FILE))
  
  matrix_estim <- reactive({
    if(!input$subsetmat){
      task$result()
    }else{
      task$result()[input$matrmin:input$matrmax,input$matcmin:input$matcmax]
    }
  })
  
  
  output$Mhat <- renderTable({
    matrix_estim()
  })
  
  output$download_matrix <- downloadHandler(filename = "correlation_matrix.csv",
                                            content = function(file){
                                              write.csv2(matrix_estim(),file)
                                            }
  )
  
  
  cor_plot <- function(){
    corrplot(matrix_estim(),type="upper",method=input$corrplot_type)
  }
  
  output$corr_plot <- renderPlot({
    cor_plot()
  })
  
  output$download_corrplot <- downloadHandler(filename = "corrplot.png",
                                              content = function(file){
                                                png(file)
                                                cor_plot()
                                                dev.off()
                                              }
  )
  
  observeEvent(input$other_group,
               {
                 if(input$other_group){
                   shinyjs::hide(id="colcont")
                   shinyjs::hide(id="coldisc")
                 }else{
                   shinyjs::show(id="colcont")
                   shinyjs::show(id="coldisc")
                 }
               })
  
  new_groups <- reactive({
    input$nbgps
  })
  
  
  output$groups1 <- renderUI({
    output = tagList()
    for(i in 1:new_groups()){
      output[[i]] = tagList()
      output[[i]][[1]]=colourpicker::colourInput(inputId = paste0("colorgp", i), label = paste0("Select the color for group ",i))
    }
    output
  })
  
  output$groups3 <- renderUI({
    output = tagList()
    for(i in 1:new_groups()){
      output[[i]] = tagList()
      output[[i]][[1]]=textInput(inputId = paste0("numgp", i), label = paste0("Select the columns for group ",i))
    }
    output
  })
  
  output$groups2 <- renderUI({
    output = tagList()
    for(i in 1:new_groups()){
      output[[i]] = tagList()
      output[[i]][[1]]=textInput(inputId = paste0("labelgp", i), label = paste0("Enter the label for group ",i))
    }
    output
  })
  
  color <- reactive({
    col <- rep(NA,length(type_vec()))
    col_order <- c()
    if(!input$custom){
      col[which(type_vec()=="C")] <- "goldenrod1"
      col[which(type_vec()=="D")] <- "lightskyblue"
      col_order <- c("goldenrod1","lightskyblue")
    }else if(!input$other_group){
      col[which(type_vec()=="C")] <- input$colcont
      col[which(type_vec()=="D")] <- input$coldisc
      col_order <- c(input$colcont,input$coldisc)
    }else{
      col_order <- c()
      for(i in 1:new_groups()){
        id <- paste0("numgp",i)
        color_new <- paste0("colorgp",i)
        col[as.numeric(unlist(strsplit(input[[id]],",")))] <- input[[color_new]]
        col_order <-c(col_order,input[[color_new]])
      }
    }
    print(col)
    return(list(col,col_order))
  })
  
  legendgph <- reactive({
    if(!input$custom){
      legend <- c("Continuous","Discrete")
    }else if(!input$other_group){
      legend <- c("Continuous","Discrete")
    }else{
      legend <- c()
      for(i in 1:new_groups()){
        labelgp <- paste0("labelgp",i)
        legend <- c(legend,input[[labelgp]])
      }
      print(legend)
    }
    return(legend)
  })
  
  network_ref_estim <- reactive(graph_from_adjacency_matrix(matrix_cor_ts(round(matrix_estim(),3), input$T_hat), mode="undirected", diag=F))
  
  plot_hat <- function(){
    par(xpd=TRUE)
    plot(network_ref_estim(),vertex.color=color()[[1]])
    legend("bottomright",inset=c(-0,-0.15), legendgph(),fill=color()[[2]])
  }
  
  output$plot <- renderPlot(plot_hat())
  
  output$download_plot <- downloadHandler(filename = "graph.png",
                                          content = function(file){
                                            png(file)
                                            plot_hat()
                                            dev.off()
                                          }
  )
  
}



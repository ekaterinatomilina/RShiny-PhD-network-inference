server <- function(input, output,session) {
  
  # All that's related to the data, common for cor and cov
  
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
  },align="c")
  
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
  
  
  # CORRELATION 
  
  # Estimation
  
  PROGRESS_FILE <- "progress.txt"
  
  task <- ExtendedTask$new(function(data,type){
    mirai({
      sink(PROGRESS_FILE,type="output")
      on.exit(sink())
      rho_estim(data,type,ncores=2)
    }, rho_estim=rho_estim,data=data,type=type,PROGRESS_FILE = PROGRESS_FILE)
  })
  
  observeEvent(input$dataset, task$invoke(dataframe(),type_vec()))
  
  progress <- reactiveFileReader(100, session, PROGRESS_FILE, function(path) {
    if (file.exists(path)) {
      lignes <- readLines(path, warn = FALSE)
      return(lignes)
    }
    return(character(0))
  })
  
  output$progress <- renderText({
    paste(progress(), collapse = "\n")
  })
  
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
  },align="c")
  
  output$download_matrix <- downloadHandler(filename = "correlation_matrix.csv",
                                            content = function(file){
                                              write.csv2(matrix_estim(),file)
                                            }
  )
  
  # Corrplot
  
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
  
  # Représentation graphique
  
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
  # PRECISION
  
  #Selection du lambda
  lambdaopt <- reactive({
    
    if (!isTRUE(input$lambdagrid)) {
      return(NULL)  # pas de calcul si on ne spécifie pas une grille
    }
    
    n <- nrow(dataframe())
    d <- ncol(dataframe())
    
    lambda_list <- seq(input$lambdamin,input$lambdamax,input$lambdastep)
    crit <- c()
    for(l in lambda_list){
      OM_hat <-  huge::huge(matrix_estim(),lambda=l,method="glasso")$icov[[1]]
      c <- matrix.trace(matrix_estim() %*%OM_hat)-log(det(OM_hat))+log(log(n))*(log(d)/n)*sum(OM_hat!=0)
      crit <- c(crit, c)
    }
    
    crit_min <- min(crit,na.rm=T)
    lambdaopt <- lambda_list[which(crit==crit_min)]
    
    return(list(lambda_list,crit,lambdaopt))

  })
  
  plot_crit <- function(){ 
    req(lambdaopt())  # pas de plot si pas calculé
    par(xpd=TRUE)
    plot(lambdaopt()[[1]],lambdaopt()[[2]],xlab="HBIC",ylab="lambda",type="l")
    abline(v=lambdaopt()[[3]],col="red",lty=3)
  }
  
  
  output$crit_lamb <-renderPlot({
    req(input$lambdagrid)
    plot_crit()
  })
  
  output$download_crit <- downloadHandler(filename = "HBIC.png",
                                           content = function(file){
                                             req(input$lambdagrid)
                                             png(file)
                                             plot_crit()
                                             dev.off()
                                           }
  )
  
  #Estimation
  matrix_prec <- reactive({
    lambda_val <- if (isTRUE(input$lambdagrid)) {
      lambdaopt()[[3]]
    } else {
      input$lambda
    }
   OM_hat <-  huge::huge(matrix_estim(),lambda=lambda_val,method="glasso")$icov[[1]]
   
  return(OM_hat)
   })

  output$OMhat <- renderTable({
    matrix_prec()
     },align="c")
  
  output$download_matrix2 <- downloadHandler(filename = "precision_matrix.csv",
                                            content = function(file){
                                              write.csv2(matrix_prec(),file)
                                            }
  )
  
  # Graphical rep
  
  observeEvent(input$other_group2,
               {
                 if(input$other_group2){
                   shinyjs::hide(id="colcont2")
                   shinyjs::hide(id="coldisc2")
                 }else{
                   shinyjs::show(id="colcont2")
                   shinyjs::show(id="coldisc2")
                 }
               })
  
  new_groups2 <- reactive({
    input$nbgps2
  })
  
  
  output$groups21 <- renderUI({
    output = tagList()
    for(i in 1:new_groups2()){
      output[[i]] = tagList()
      output[[i]][[1]]=colourpicker::colourInput(inputId = paste0("colorgppr2", i), label = paste0("Select the color for group ",i))
    }
    output
  })
  
  output$groups23 <- renderUI({
    output = tagList()
    for(i in 1:new_groups2()){
      output[[i]] = tagList()
      output[[i]][[1]]=textInput(inputId = paste0("numgppr2", i), label = paste0("Select the columns for group ",i))
    }
    output
  })
  
  output$groups22 <- renderUI({
    output = tagList()
    for(i in 1:new_groups2()){
      output[[i]] = tagList()
      output[[i]][[1]]=textInput(inputId = paste0("labelgppr2", i), label = paste0("Enter the label for group ",i))
    }
    output
  })
  
  color2 <- reactive({
    col <- rep(NA,length(type_vec()))
    col_order <- c()
    if(!input$custom2){
      col[which(type_vec()=="C")] <- "goldenrod1"
      col[which(type_vec()=="D")] <- "lightskyblue"
      col_order <- c("goldenrod1","lightskyblue")
    }else if(!input$other_group2){
      col[which(type_vec()=="C")] <- input$colcont2
      col[which(type_vec()=="D")] <- input$coldisc2
      col_order <- c(input$colcont2,input$coldisc2)
    }else{
      col_order <- c()
      for(i in 1:new_groups2()){
        id <- paste0("numgppr2",i)
        color_new <- paste0("colorgppr2",i)
        col[as.numeric(unlist(strsplit(input[[id]],",")))] <- input[[color_new]]
        col_order <-c(col_order,input[[color_new]])
      }
    }
    return(list(col,col_order))
  })
  
  legendgphpr <- reactive({
    if(!input$custom2){
      legend <- c("Continuous","Discrete")
    }else if(!input$other_group2){
      legend <- c("Continuous","Discrete")
    }else{
      legend <- c()
      for(i in 1:new_groups()){
        labelgp <- paste0("labelgppr2",i)
        legend <- c(legend,input[[labelgp]])
      }
    }
    return(legend)
  })
  
  network_ref_estimpr <- reactive(graph_from_adjacency_matrix(matrix_cor_ts(matrix_prec(),0.01), mode="undirected", diag=F))
  
  plot_hat2 <- function(){
    par(xpd=TRUE)
    plot(network_ref_estimpr(),vertex.color=color2()[[1]])
    legend("bottomright",inset=c(-0,-0.15), legendgphpr(),fill=color2()[[2]])
  }
  
  output$plot2 <- renderPlot(plot_hat2())
  
  output$download_plot2 <- downloadHandler(filename = "graph.png",
                                          content = function(file){
                                            png(file)
                                            plot_hat2()
                                            dev.off()
                                          }
  )
  
}



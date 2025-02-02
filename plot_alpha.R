library(MASS)
library(tidyverse)
library(cowplot)


plot.alpha <- function(x, nburn, thinning, ...) {
  
  if(missing(x)) stop("'x' needs to be supplied")
  if (class(x) != "dpmm_fit") {
    if (is.list(x) == TRUE) {
      if (class(x[[1]]) != "dpmm_fit") stop("'x' needs to be of class 'dpmm_fit' or a list of 'dpmm_fit'")
    } else {
      stop("'x' needs to be of class 'dpmm_fit' or a list of 'dpmm_fit'")
    }
  }
  
  if(missing(nburn)) stop("'nburn' must be provided")
  if(!missing(nburn)) {
    if (is.numeric(nburn) == FALSE) {
      stop("'nburn' must be numeric")
    }
  }
  
  if(missing(thinning)) stop("'thinning' needs to be supplied")
  if(!missing(thinning)) {
    if (is.numeric(thinning) == FALSE) {
      stop("'thinning' must be numeric")
    }
  }
  
  
  summary.clusters_complete <- NULL
  postComp_complete <- NULL
  postAlpha_complete <- NULL
  
  
  if (class(x) == "dpmm_fit") {
    
    
    samples <- x$samples
    
    iterations <- seq(nburn,nrow(samples),1000)
    samples_summary <- samples %>%
      select(starts_with("z"))
    summary.clusters <- NULL
    for (i in iterations) {
      row_summary <- samples_summary[i,] %>% t() %>% factor() %>% summary()
      summary.clusters <- dplyr::bind_rows(summary.clusters, row_summary)
    }
    title_chain <- paste0("Chain 1")
    summary.clusters <- summary.clusters %>%
      apply(1, function(x) x[order(x, decreasing = TRUE)]) %>%
      t() %>%
      as.data.frame() %>%
      mutate_all(~replace(., is.na(.), 0)) %>%
      colMeans() %>%
      as.data.frame() %>%
      setNames(c("value"))
    
    summary.clusters <- summary.clusters %>%
      mutate(key = rep(as.character(1:nrow(summary.clusters)),1)) %>%
      mutate(key = factor(key, levels = as.character(1:nrow(summary.clusters)))) %>%
      cbind(Chain = rep(title_chain, nrow(summary.clusters)))
    
    summary.clusters_complete <- rbind(summary.clusters_complete, summary.clusters) 
    
    
    postComp <- samples %>% 
      select(starts_with("z")) %>%
      apply(1, function(x)  length(unique(x))) %>%
      as.data.frame() %>%
      cbind(Iteration = rep(1:nrow(samples), 1)) %>%
      cbind(Chain = rep(title_chain, nrow(samples)))
    
    postComp_complete <- rbind(postComp_complete, postComp)
    
    postAlpha <- samples %>%
      select("alpha") %>%
      mutate(Iteration = rep(1:nrow(samples), 1)) %>%
      cbind(Chain = rep(title_chain, nrow(samples)))
    
    postAlpha_complete <- rbind(postAlpha_complete, postAlpha)
    
    
  } else {
    
    
    for (chain in 1:length(x)) { 
      
      samples <- x[[chain]]$samples
      
      iterations <- seq(nburn,nrow(samples),1000)
      samples_summary <- samples %>%
        select(starts_with("z"))
      summary.clusters <- NULL
      for (i in iterations) {
        row_summary <- samples_summary[i,] %>% t() %>% factor() %>% summary()
        summary.clusters <- dplyr::bind_rows(summary.clusters, row_summary)
      }
      title_chain <- paste0("Chain ",chain)
      summary.clusters <- summary.clusters %>%
        apply(1, function(x) x[order(x, decreasing = TRUE)]) %>%
        t() %>%
        as.data.frame() %>%
        mutate_all(~replace(., is.na(.), 0)) %>%
        colMeans() %>%
        as.data.frame() %>%
        setNames(c("value"))
      
      summary.clusters <- summary.clusters %>%
        mutate(key = rep(as.character(1:nrow(summary.clusters)),1)) %>%
        mutate(key = factor(key, levels = as.character(1:nrow(summary.clusters)))) %>%
        cbind(Chain = rep(title_chain, nrow(summary.clusters)))
      
      summary.clusters_complete <- rbind(summary.clusters_complete, summary.clusters) 
      
      
      postComp <- samples %>% 
        select(starts_with("z")) %>%
        apply(1, function(x)  length(unique(x))) %>%
        as.data.frame() %>%
        cbind(Iteration = rep(1:nrow(samples), 1)) %>%
        cbind(Chain = rep(title_chain, nrow(samples)))
      
      postComp_complete <- rbind(postComp_complete, postComp)
      
      postAlpha <- samples %>%
        select("alpha") %>%
        mutate(Iteration = rep(1:nrow(samples), 1)) %>%
        cbind(Chain = rep(title_chain, nrow(samples)))
      
      postAlpha_complete <- rbind(postAlpha_complete, postAlpha)
      
      
    }
    
  }
  
  
  
  summary.clusters_complete <- summary.clusters_complete %>%
    mutate(Chain = factor(Chain))
  
  postComp_complete <- postComp_complete %>%
    mutate(Chain = factor(Chain))
  
  postAlpha_complete <- postAlpha_complete %>%
    mutate(Chain = factor(Chain))
  
  
  #plot
  plot <- plot_grid(
    
    plot_grid(
      
      postComp_complete %>%
        ggplot() +
        geom_path(aes(x = Iteration, y = `.`, colour = Chain), size = 0.4, alpha = 0.7) +
        theme_bw() +
        scale_y_continuous(breaks = seq(1,200, by =1)) +
        labs(title = "Number of Components",
             x = "Iterations",
             y = "Components") +
        theme(legend.position = "none")
      
      ,
      
      summary.clusters_complete %>%
        ggplot() +
        geom_col(aes(x = key, y = value, colour = Chain, fill = Chain), size = 0.2, position = "dodge2") +
        theme_bw() +
        labs(title = "Average Number of Individuals for Ranked Components",
             x = "Component Ranking",
             y = "Individuals") +
        theme(legend.position = "none")
      ,
      
      ncol = 2, rel_widths = c(15,28), labels = c("A","B")
      
      
    )
    
    ,
    
    postAlpha_complete %>%
      ggplot() +
      geom_line(aes(x = Iteration, y = alpha, colour = Chain), alpha = 0.7) +
      theme_bw() +
      labs(title = "Alpha values",
           x = "Iterations") +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "none")
    ,
    
    ncol = 1, nrow = 2, rel_heights = c(23,16), labels = c("","C")
    
    
  )
  
  return(plot)
}




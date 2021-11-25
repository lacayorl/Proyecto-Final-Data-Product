library(shiny)
library(dplyr)
library(tidyr)
library(highcharter)
library(lubridate)
library(viridisLite)
library(leaflet)
library(RMySQL)
library(DBI)
library(ggplot2)
library(plotly)
library(scales)

## ----- Datos ----- ##

db <- dbConnect(MySQL(),
                user = "test",
                db = "test",
                host = "db",
                password = "test123",
                port = 3306)
recuperados <- dbReadTable(db,"recuperados")
confirmados <- dbReadTable(db,"covidianos")
muertos <- dbReadTable(db,"muertos")

confirmados$fecha <- ymd_hms(confirmados$fecha)
recuperados$fecha <- ymd_hms(recuperados$fecha)
muertos$fecha <- ymd_hms(muertos$fecha)




## ----------------- ##



shinyServer(function(input, output, session) {
    
    output$plot1 <- renderHighchart({
        ts_confirmados2 <- confirmados %>% group_by(country) %>% 
            filter(fecha==max(fecha)) %>% 
            summarise(casos=sum(valor)) %>% 
            mutate(status='Confirmados')
        ts_recuperados2 <- recuperados %>% group_by(country) %>% 
            filter(fecha==max(fecha)) %>% 
            summarise(casos=sum(valor)) %>% 
            mutate(status='Recuperados')
        ts_muertos2 <- muertos %>% group_by(country) %>% 
            filter(fecha==max(fecha)) %>% 
            summarise(casos=sum(valor)) %>% 
            mutate(status='Muertos')
        df_ts2 <- rbind(ts_confirmados2,ts_recuperados2,ts_muertos2)
        df_ts2 <- df_ts2 %>% filter(status=='Confirmados')
        df_ts2 <- df_ts2[order(df_ts2$casos, decreasing = T),]
        df_ts2 <- df_ts2[1:10,]
        hchart(df_ts2, "column", 
               color = "orange",
               hcaes(x = country, y = casos),
               stacking = "normal") %>% 
            hc_xAxis(
                title = list(text = "Paises"),
                opposite = F) %>% 
            hc_yAxis(tittle = list(text="Casos")) %>% 
            hc_title(text = "Casos de COVID-19 por paises a la fecha",
                     margin = 20,
                     align = "left",
                     style = list(color = "#0000FF", useHTML = TRUE))
    })
    
    
    output$plot2 <- renderPlotly({
        
        # ts confirmados
        ts_confirmados <- confirmados %>% 
            filter(fecha >= input$date1[1]) %>%
            filter(fecha <= input$date1[2]) %>%
            group_by(fecha) %>% 
            summarise(casos=sum(valor)) %>% 
            mutate(status='confirmados')
        # ts recuperados
        ts_recuperados <- recuperados %>% 
            filter(fecha >= input$date1[1]) %>%
            filter(fecha <= input$date1[2]) %>%
            group_by(fecha) %>% 
            summarise(casos=sum(valor)) %>% 
            mutate(status='recuperados')
        # ts muertos
        ts_muertos <- muertos %>% 
            filter(fecha >= input$date1[1]) %>%
            filter(fecha <= input$date1[2]) %>%
            group_by(fecha) %>% 
            summarise(casos=sum(valor)) %>% 
            mutate(status='muertos')
        
        # Grafica 1
        
        df_ts <- rbind(ts_confirmados,ts_muertos,ts_recuperados)
        ggg <- ggplot(df_ts,aes(x = fecha, y = casos, group = status))+
            geom_line(mapping = aes(color = status))+
            scale_y_continuous(labels = unit_format(unit = "M", scale = 1e-6))+
            labs(title = "Casos de COVID-19 por Status")+
            theme_minimal()
        ggplotly(ggg)
        
        
    })
    
    observeEvent(input$clean,{
        updateDateRangeInput(session,'date1', start = min(confirmados$fecha),
                             end = max(confirmados$fecha))
    })
    
    observeEvent(input$graphBar,{
        ts_confirmados2 <- confirmados %>% group_by(country) %>% 
            filter(fecha==max(fecha)) %>% 
            summarise(casos=sum(valor)) %>% 
            mutate(status='Confirmados')
        ts_recuperados2 <- recuperados %>% group_by(country) %>% 
            filter(fecha==max(fecha)) %>% 
            summarise(casos=sum(valor)) %>% 
            mutate(status='Recuperados')
        ts_muertos2 <- muertos %>% group_by(country) %>% 
            filter(fecha==max(fecha)) %>% 
            summarise(casos=sum(valor)) %>% 
            mutate(status='Muertos')
        df_ts3 <- rbind(ts_confirmados2,ts_recuperados2,ts_muertos2)
        df_ts3 <- df_ts3[df_ts3$country %in% input$selectPaises,]
        
        output$plot1 <- renderHighchart({
            
            hchart(df_ts3, "column", 
                   color = "orange",
                   hcaes(x = country, y = casos),
                   stacking = "normal") %>% 
                hc_xAxis(
                    title = list(text = "Paises"),
                    opposite = F) %>% 
                hc_yAxis(tittle = list(text="Casos")) %>% 
                hc_title(text = "Casos de COVID-19 por paises a la fecha",
                         margin = 20,
                         align = "left",
                         style = list(color = "#0000FF", useHTML = TRUE))
            
        })
        
    })
        
        observeEvent(input$graphMap,{
            
            if(input$statusButton =='confirmados'){
                data_map_confirmados <- confirmados %>% 
                    filter(fecha==max(fecha)) %>%
                    group_by(country) %>%
                    summarise(casos=sum(valor, na.rm = T), 
                              lat=mean(latitud, na.rm = T), 
                              lng=mean(longitud, na.rm = T)) %>%
                    mutate(Proporcion = (casos/sum(casos))*100)
                data_map_confirmados <- data_map_confirmados[data_map_confirmados$country %in%
                                                                 input$pickerPaises, ]
                
                output$mapa <- renderLeaflet({
                    leaflet() %>%
                        addTiles() %>%
                        addCircles(lng = data_map_confirmados$lng, 
                                   lat = data_map_confirmados$lat, 
                                   weight = 1, radius = data_map_confirmados$Proporcion*10e4, color =  "black",
                                   fillColor = "blue", fillOpacity=0.5, opacity=1)
                    
                })
                
            } else {
                
                data_map_muertos <- muertos %>% 
                    filter(fecha==max(fecha)) %>%
                    group_by(country) %>%
                    summarise(casos=sum(valor, na.rm = T), 
                              lat=mean(latitud, na.rm = T), 
                              lng=mean(longitud, na.rm = T)) %>%
                    mutate(Proporcion = (casos/sum(casos))*100)
                data_map_muertos <- data_map_muertos[data_map_muertos$country %in%
                                                                 input$pickerPaises, ]
                
                output$mapa <- renderLeaflet({
                    leaflet() %>%
                        addTiles() %>%
                        addCircles(lng = data_map_muertos$lng, 
                                   lat = data_map_muertos$lat, 
                                   weight = 1, radius = data_map_muertos$Proporcion*10e4, color =  "black",
                                   fillColor = "red", fillOpacity=0.5, opacity=1)
                    
                })
            }
        
        })
    

})

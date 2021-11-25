library(shiny)
library(shinydashboard)
library(formattable)
library(shinyWidgets)
library(leaflet)
library(dplyr)
library(tidyr)
library(lubridate)
library(highcharter)
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



sidebar <- dashboardSidebar(
    sidebarMenu(
        menuItem("Global Stats",tabName = "dashboard", icon = icon("dashboard"),
                 badgeLabel = max(confirmados$fecha), badgeColor = "green"),
        menuItem("Filters",icon = icon("th"), tabName = "widgets")
    )
)

### ---------- Global stats values -----------------
N_paises <- length(unique(confirmados$country))
confirmados_mundial <- confirmados %>% filter(fecha==max(fecha)) %>% 
    group_by(country) %>% summarise(casos=sum(valor))
confirmados_mundial <- sum(confirmados_mundial$casos)
muertos_mundial <- muertos %>% filter(fecha==max(fecha)) %>% 
    group_by(country) %>% summarise(casos=sum(valor))
muertos_mundial <- sum(muertos_mundial$casos)
promedio_muertos <- round(muertos_mundial/as.double(difftime(time1 = max(muertos$fecha),
                                             time2 = min(muertos$fecha), 
                                             units = "days")),0)
mortalidad <- (muertos_mundial/confirmados_mundial) *100

### --------------------------------------------
countries <- unique(confirmados$country)

body <- dashboardBody(
    tabItems(
        tabItem(tabName = "dashboard",
                h2("Estadisticas Globales"),
                fluidRow(
                    # A static valorBox
                    valueBox(comma(N_paises, digits = 0), "Total Countries", icon = icon("calendar"), 
                             color = "green"),
                    valueBox(comma(confirmados_mundial, digits = 0), "Confirmed Cases", icon("fa fa-biohazard"),
                             color = "blue"),
                    valueBox(comma(muertos_mundial, digits = 0), "Deaths", 
                             color = "red"),
                    valueBox(paste0(round(mortalidad,2)," %"), "Tasa agregada de mortalidad",
                             color = "purple"),
                    valueBox(comma(promedio_muertos, digits = 0), "Muertes diarias",
                             color = "orange"),
                ),
                fluidRow(
                    box(title = "Bar Chart", status = "primary", highchartOutput("plot1", height = 250)),
                    
                    box(
                        title = "Select Countries", status = "primary",
                        "Seleccione los paises para ver la grafica de barras por pais",
                        multiInput(
                            inputId = "selectPaises",
                            label = "Countries :", 
                            choices = countries
                        ),
                        actionButton("graphBar", "Graficar")
                    )
                ),
                fluidRow(
                    box(title = "Time Series", status = "warning", plotlyOutput("plot2", height = 250)),
                    box(
                        title = "Date Range", status = "warning",
                        "Seleccione un rango de fechas para ver la serie de tiempo por status de casos",
                        dateRangeInput("date1",
                                       format = "yyy-mm-dd",
                                       label = "Rango",
                                       start = min(confirmados$fecha),
                                       end = max(confirmados$fecha),
                                       min = min(confirmados$fecha),
                                       max = max(confirmados$fecha)
                        ),
                        actionButton("clean", "Inicializar rango")
                    )
                )
        ),
        tabItem(tabName = "widgets",
                h2("Mapa por status"),
                fluidRow(
                    box(title = "Map selection", status = "primary",
                        radioGroupButtons(
                            inputId = "statusButton",
                            label = "Seleccione el tipo de casos", 
                            choices = c("confirmados", "muertos"),
                            status = "primary"
                        ),
                        pickerInput(
                            inputId = "pickerPaises",
                            label = "Seleccione los paises a mostrar en el mapa", 
                            choices = countries,
                            multiple = TRUE,
                            selected = "Badge danger"
                        ),
                        actionButton("graphMap", "Graficar Mapa")
                    )
                    
                ),
                fluidRow(
                    leafletOutput("mapa", width = "100%", height = 400)
                    )
                )
                
    
    )
)

shinyUI(dashboardPage(
    dashboardHeader(title = "COVID-19 Dashboard"),
    sidebar,
    body
))

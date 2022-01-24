# https://grafana.com/grafana/dashboards/14314
apiVersion: v1
kind: ConfigMap
metadata:
  name: dashboard-ingress-nginx-${name}
  labels:
    grafana_dashboard: "1"
  namespace: ${namespace}
data:
  ingress-nginx-${name}.json: |-
    {
      "__inputs": [
        {
          "name": "DS_PROMETHEUS",
          "label": "Prometheus",
          "description": "",
          "type": "datasource",
          "pluginId": "prometheus",
          "pluginName": "Prometheus"
        }
      ],
      "__requires": [
        {
          "type": "grafana",
          "id": "grafana",
          "name": "Grafana",
          "version": "6.7.0"
        },
        {
          "type": "datasource",
          "id": "prometheus",
          "name": "Prometheus",
          "version": "5.0.0"
        },
        {
          "type": "panel",
          "id": "singlestat",
          "name": "Singlestat",
          "version": "5.0.0"
        }
      ],
      "annotations": {
        "list": [
          {
            "builtIn": 1,
            "datasource": "-- Grafana --",
            "enable": true,
            "hide": true,
            "iconColor": "rgba(0, 211, 255, 1)",
            "name": "Annotations & Alerts",
            "type": "dashboard"
          },
          {
            "datasource": "$${DS_PROMETHEUS}",
            "enable": true,
            "expr": "sum(changes(nginx_ingress_controller_config_last_reload_successful_timestamp_seconds{instance!=\"unknown\",controller_class=~\"$controller_class\",namespace=~\"$namespace\"}[30s])) by (controller_class)",
            "hide": false,
            "iconColor": "rgba(255, 96, 96, 1)",
            "limit": 100,
            "name": "Config Reloads",
            "showIn": 0,
            "step": "30s",
            "tagKeys": "controller_class",
            "tags": [],
            "titleFormat": "Config Reloaded",
            "type": "tags"
          }
        ]
      },
      "editable": true,
      "gnetId": 14314,
      "graphTooltip": 0,
      "id": 35,
      "iteration": 1619515274866,
      "links": [],
      "panels": [
        {
          "collapsed": false,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 0
          },
          "id": 31,
          "panels": [],
          "title": "Overview",
          "type": "row"
        },
        {
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": "$${DS_PROMETHEUS}",
          "decimals": 1,
          "description": "This is the total number of requests made in this period (top-right period selected)",
          "fieldConfig": {
            "defaults": {
              "custom": {}
            },
            "overrides": []
          },
          "format": "short",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 3,
            "w": 3,
            "x": 0,
            "y": 1
          },
          "id": 8,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(increase(nginx_ingress_controller_requests{ controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$${__range_s}s]))",
              "format": "time_series",
              "intervalFactor": 1,
              "legendFormat": "",
              "refId": "A"
            }
          ],
          "title": "Requests (period)",
          "type": "singlestat",
          "valueFontSize": "100%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": null,
          "decimals": 1,
          "description": "This is the percentage of successful requests over the entire period in the top-right hand corner.\n\nNOTE: Ignoring 404s in this metric, since a 404 is a normal response for errant/invalid request.  This helps prevent this percentage from being affected by typical web scanners and security probes.",
          "fieldConfig": {
            "defaults": {
              "custom": {}
            },
            "overrides": []
          },
          "format": "percentunit",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 3,
            "w": 2,
            "x": 3,
            "y": 1
          },
          "id": 14,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(\n  rate(\n    nginx_ingress_controller_requests{status!~\"[4-5].*\", controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$${__range_s}s]\n      )\n   )   \n/ \n(\n  sum(\n    rate(\n      nginx_ingress_controller_requests{ controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$${__range_s}s]\n        )\n     ) - \n  (\n  sum(\n    rate(\n      nginx_ingress_controller_requests{status=~\"404|499\", controller_class=~\"$controller_class\", ingress=~\"$ingress\",namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$${__range_s}s]\n        )\n     ) \n  or vector(0)\n  )\n)",
              "format": "time_series",
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "",
              "refId": "A"
            }
          ],
          "thresholds": "",
          "timeFrom": null,
          "timeShift": null,
          "title": "% Success (period)",
          "type": "singlestat",
          "valueFontSize": "80%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": null,
          "decimals": 0,
          "description": "This is the number of new connections made to the controller in the last minute.  NOTE: This metric does not support the Ingress, Namespace variables, as this is at a lower-level than the actual application.  It does support the others though (Env, Controller Class, Pod)",
          "fieldConfig": {
            "defaults": {
              "custom": {}
            },
            "overrides": []
          },
          "format": "none",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 3,
            "w": 2,
            "x": 5,
            "y": 1
          },
          "id": 6,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(avg_over_time(nginx_ingress_controller_nginx_process_connections{state=~\"active\", state=~\"active\",  controller_class=~\"$controller_class\", controller_pod=~\"$pod\"}[$__interval]))",
              "format": "time_series",
              "interval": "2m",
              "intervalFactor": 1,
              "legendFormat": "{{ingress}}",
              "refId": "A"
            }
          ],
          "thresholds": "",
          "timeFrom": null,
          "timeShift": null,
          "title": "Conns (2m)",
          "type": "singlestat",
          "valueFontSize": "80%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": false,
          "colors": [
            "#299c46",
            "rgba(237, 129, 40, 0.89)",
            "#d44a3a"
          ],
          "datasource": null,
          "decimals": 0,
          "description": "The number of HTTP requests made in the last 1 minute window",
          "fieldConfig": {
            "defaults": {
              "custom": {}
            },
            "overrides": []
          },
          "format": "short",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 3,
            "w": 2,
            "x": 7,
            "y": 1
          },
          "id": 7,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": false
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(increase(nginx_ingress_controller_requests{ controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$__interval]))",
              "format": "time_series",
              "interval": "2m",
              "intervalFactor": 1,
              "legendFormat": "",
              "refId": "A"
            }
          ],
          "thresholds": "",
          "timeFrom": null,
          "timeShift": null,
          "title": "Reqs (2m)",
          "type": "singlestat",
          "valueFontSize": "80%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": true,
          "colorValue": false,
          "colors": [
            "#d44a3a",
            "rgba(237, 129, 40, 0.89)",
            "#299c46"
          ],
          "datasource": null,
          "description": "This is the percentage of successful requests over the last minute.\n\nNOTE: Ignoring 404s in this metric, since a  404 is a normal response for errant requests",
          "fieldConfig": {
            "defaults": {
              "custom": {}
            },
            "overrides": []
          },
          "format": "percentunit",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 3,
            "w": 3,
            "x": 9,
            "y": 1
          },
          "id": 13,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": false,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(rate(nginx_ingress_controller_requests{status!~\"[4-5].*\", controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$__interval])) / \n(sum(rate(nginx_ingress_controller_requests{ controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$__interval])) - \n(sum(rate(nginx_ingress_controller_requests{status=~\"404|499\", controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$__interval])) or vector(0)))",
              "format": "time_series",
              "interval": "2m",
              "intervalFactor": 1,
              "legendFormat": "",
              "refId": "A"
            }
          ],
          "thresholds": "0.8,0.9",
          "timeFrom": null,
          "timeShift": null,
          "title": "% Success (2m)",
          "type": "singlestat",
          "valueFontSize": "100%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": true,
          "colors": [
            "#73BF69",
            "#73BF69",
            "#73BF69"
          ],
          "datasource": "$${DS_PROMETHEUS}",
          "decimals": 0,
          "description": "This is the number of successful requests in the last minute.  Successful being 1xx or 2xx by the standard HTTP definition.",
          "fieldConfig": {
            "defaults": {
              "custom": {}
            },
            "overrides": []
          },
          "format": "short",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 3,
            "w": 3,
            "x": 12,
            "y": 1
          },
          "id": 12,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": true,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(increase(nginx_ingress_controller_requests{status=~\"(1|2).*\",  controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$__interval])) or vector(0)",
              "format": "time_series",
              "interval": "2m",
              "intervalFactor": 1,
              "legendFormat": "",
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "HTTP 1/2xx (2m)",
          "transparent": true,
          "type": "singlestat",
          "valueFontSize": "150%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorPrefix": false,
          "colorValue": true,
          "colors": [
            "#3274D9",
            "#3274D9",
            "#3274D9"
          ],
          "datasource": "$${DS_PROMETHEUS}",
          "decimals": 0,
          "description": "This is the number of 3xx requests in the last minute.",
          "fieldConfig": {
            "defaults": {
              "custom": {}
            },
            "overrides": []
          },
          "format": "short",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 3,
            "w": 3,
            "x": 15,
            "y": 1
          },
          "id": 10,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": true,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(increase(nginx_ingress_controller_requests{status=~\"3.*\",  controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[2m]))  or vector(0)",
              "format": "time_series",
              "interval": "$__interval",
              "intervalFactor": 1,
              "legendFormat": "",
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "HTTP 3xx (2m)",
          "transparent": true,
          "type": "singlestat",
          "valueFontSize": "150%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": true,
          "colors": [
            "#FF9830",
            "#FF9830",
            "#FF9830"
          ],
          "datasource": "$${DS_PROMETHEUS}",
          "decimals": 0,
          "description": "This is the number of 4xx requests in the last minute.",
          "fieldConfig": {
            "defaults": {
              "custom": {}
            },
            "overrides": []
          },
          "format": "short",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 3,
            "w": 3,
            "x": 18,
            "y": 1
          },
          "id": 18,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": true,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(increase(nginx_ingress_controller_requests{status=~\"4.*\",  controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$__interval]))  or vector(0)",
              "format": "time_series",
              "interval": "2m",
              "intervalFactor": 1,
              "legendFormat": "",
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "HTTP 4xx (2m)",
          "transparent": true,
          "type": "singlestat",
          "valueFontSize": "150%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "cacheTimeout": null,
          "colorBackground": false,
          "colorValue": true,
          "colors": [
            "#F2495C",
            "#F2495C",
            "#F2495C"
          ],
          "datasource": "$${DS_PROMETHEUS}",
          "decimals": 0,
          "description": "This is the number of 5xx requests in the last minute.",
          "fieldConfig": {
            "defaults": {
              "custom": {}
            },
            "overrides": []
          },
          "format": "short",
          "gauge": {
            "maxValue": 100,
            "minValue": 0,
            "show": false,
            "thresholdLabels": false,
            "thresholdMarkers": true
          },
          "gridPos": {
            "h": 3,
            "w": 3,
            "x": 21,
            "y": 1
          },
          "id": 11,
          "interval": null,
          "links": [],
          "mappingType": 1,
          "mappingTypes": [
            {
              "name": "value to text",
              "value": 1
            },
            {
              "name": "range to text",
              "value": 2
            }
          ],
          "maxDataPoints": 100,
          "nullPointMode": "connected",
          "nullText": null,
          "postfix": "",
          "postfixFontSize": "50%",
          "prefix": "",
          "prefixFontSize": "50%",
          "rangeMaps": [
            {
              "from": "null",
              "text": "N/A",
              "to": "null"
            }
          ],
          "sparkline": {
            "fillColor": "rgba(31, 118, 189, 0.18)",
            "full": true,
            "lineColor": "rgb(31, 120, 193)",
            "show": true
          },
          "tableColumn": "",
          "targets": [
            {
              "expr": "sum(increase(nginx_ingress_controller_requests{status=~\"5.*\", controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$__interval])) or vector(0)",
              "format": "time_series",
              "interval": "2m",
              "intervalFactor": 1,
              "legendFormat": "",
              "refId": "A"
            }
          ],
          "thresholds": "",
          "title": "HTTP 5xx (2m)",
          "transparent": true,
          "type": "singlestat",
          "valueFontSize": "150%",
          "valueMaps": [
            {
              "op": "=",
              "text": "N/A",
              "value": "null"
            }
          ],
          "valueName": "current"
        },
        {
          "aliasColors": {},
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": null,
          "description": "This is a total number of requests broken down by the ingress.  This can help get a sense of scale in relation to each other.",
          "fieldConfig": {
            "defaults": {
              "custom": {},
              "links": []
            },
            "overrides": []
          },
          "fill": 1,
          "fillGradient": 0,
          "gridPos": {
            "h": 8,
            "w": 8,
            "x": 0,
            "y": 4
          },
          "hiddenSeries": false,
          "id": 2,
          "legend": {
            "avg": false,
            "current": false,
            "max": false,
            "min": false,
            "show": false,
            "total": false,
            "values": false
          },
          "lines": true,
          "linewidth": 1,
          "links": [],
          "nullPointMode": "null",
          "options": {
            "alertThreshold": true
          },
          "paceLength": 10,
          "percentage": false,
          "pluginVersion": "7.4.3",
          "pointradius": 2,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "sum(increase(nginx_ingress_controller_requests{ controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$__interval])) by (ingress)",
              "format": "time_series",
              "interval": "2m",
              "intervalFactor": 1,
              "legendFormat": "{{ingress}}",
              "refId": "A"
            }
          ],
          "thresholds": [],
          "timeRegions": [],
          "title": "HTTP Requests / Ingress",
          "tooltip": {
            "shared": true,
            "sort": 0,
            "value_type": "individual"
          },
          "type": "graph",
          "xaxis": {
            "mode": "time",
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "$$hashKey": "object:3838",
              "format": "short",
              "logBase": 1,
              "show": true
            },
            {
              "$$hashKey": "object:3839",
              "format": "short",
              "logBase": 1,
              "show": true
            }
          ],
          "yaxis": {
            "align": false
          }
        },
        {
          "aliasColors": {
            "HTTP 101": "dark-green"
          },
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "description": "The breakdown of the various HTTP status codes of the requests handled within' this period that matches the variables chosen above.\n\nThis chart helps notice and dive into which service is having failures and of what kind.",
          "fieldConfig": {
            "defaults": {
              "links": []
            },
            "overrides": []
          },
          "fill": 1,
          "fillGradient": 0,
          "gridPos": {
            "h": 8,
            "w": 8,
            "x": 8,
            "y": 4
          },
          "hiddenSeries": false,
          "id": 3,
          "legend": {
            "avg": false,
            "current": false,
            "max": false,
            "min": false,
            "show": true,
            "total": false,
            "values": false
          },
          "lines": true,
          "linewidth": 1,
          "links": [],
          "nullPointMode": "null as zero",
          "options": {
            "alertThreshold": true
          },
          "paceLength": 10,
          "percentage": false,
          "pluginVersion": "7.4.3",
          "pointradius": 2,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [
            {
              "$$hashKey": "object:154",
              "alias": "/HTTP [1-2].*/i",
              "color": "#37872D"
            },
            {
              "$$hashKey": "object:155",
              "alias": "/HTTP 4.*/i",
              "color": "#C4162A"
            },
            {
              "$$hashKey": "object:156",
              "alias": "HTTP 404",
              "color": "#FF9830"
            },
            {
              "$$hashKey": "object:285",
              "alias": "HTTP 499",
              "color": "#FA6400"
            },
            {
              "$$hashKey": "object:293",
              "alias": "/HTTP 5.*/i",
              "color": "#C4162A"
            }
          ],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "sum(increase(nginx_ingress_controller_requests{ controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$__interval])) by (status)",
              "format": "time_series",
              "interval": "2m",
              "intervalFactor": 1,
              "legendFormat": "HTTP {{status}}",
              "refId": "A"
            }
          ],
          "thresholds": [],
          "timeRegions": [],
          "title": "HTTP Status Codes",
          "tooltip": {
            "shared": true,
            "sort": 0,
            "value_type": "individual"
          },
          "type": "graph",
          "xaxis": {
            "mode": "time",
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "$$hashKey": "object:182",
              "format": "short",
              "logBase": 1,
              "show": true
            },
            {
              "$$hashKey": "object:183",
              "format": "short",
              "logBase": 1,
              "show": true
            }
          ],
          "yaxis": {
            "align": false
          }
        },
        {
          "aliasColors": {},
          "bars": true,
          "dashLength": 10,
          "dashes": false,
          "description": "The total number of HTTP requests made within' each period",
          "fieldConfig": {
            "defaults": {
              "links": []
            },
            "overrides": []
          },
          "fill": 1,
          "fillGradient": 0,
          "gridPos": {
            "h": 8,
            "w": 8,
            "x": 16,
            "y": 4
          },
          "hiddenSeries": false,
          "id": 4,
          "legend": {
            "avg": false,
            "current": false,
            "max": false,
            "min": false,
            "show": false,
            "total": false,
            "values": false
          },
          "lines": false,
          "linewidth": 1,
          "links": [],
          "nullPointMode": "null",
          "options": {
            "alertThreshold": true
          },
          "paceLength": 10,
          "percentage": false,
          "pluginVersion": "7.4.3",
          "pointradius": 2,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "sum(increase(nginx_ingress_controller_requests{ controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$__interval]))",
              "format": "time_series",
              "interval": "5m",
              "intervalFactor": 1,
              "legendFormat": "{{ingress}}",
              "refId": "A"
            }
          ],
          "thresholds": [],
          "timeRegions": [],
          "title": "Total HTTP Requests",
          "tooltip": {
            "shared": true,
            "sort": 0,
            "value_type": "individual"
          },
          "type": "graph",
          "xaxis": {
            "mode": "time",
            "show": false,
            "values": []
          },
          "yaxes": [
            {
              "format": "short",
              "logBase": 1,
              "show": true
            },
            {
              "format": "short",
              "logBase": 1,
              "show": false
            }
          ],
          "yaxis": {
            "align": false
          }
        },
        {
          "aliasColors": {},
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": "$${DS_PROMETHEUS}",
          "decimals": 2,
          "editable": true,
          "error": false,
          "fill": 1,
          "grid": {},
          "gridPos": {
            "h": 8,
            "w": 8,
            "x": 0,
            "y": 12
          },
          "height": "200px",
          "id": 32,
          "isNew": true,
          "legend": {
            "alignAsTable": false,
            "avg": true,
            "current": true,
            "max": false,
            "min": false,
            "rightSide": false,
            "show": false,
            "sideWidth": 200,
            "sort": "current",
            "sortDesc": true,
            "total": false,
            "values": true
          },
          "lines": true,
          "linewidth": 2,
          "links": [],
          "nullPointMode": "connected",
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "sum (irate (nginx_ingress_controller_request_size_sum{controller_pod=~\"$pod\",controller_class=~\"$controller_class\",controller_namespace=~\"$namespace\"}[2m]))",
              "format": "time_series",
              "instant": false,
              "interval": "10s",
              "intervalFactor": 1,
              "legendFormat": "Received",
              "metric": "network",
              "refId": "A",
              "step": 10
            },
            {
              "expr": "- sum (irate (nginx_ingress_controller_response_size_sum{controller_pod=~\"$pod\",controller_class=~\"$controller_class\",controller_namespace=~\"$namespace\"}[2m]))",
              "format": "time_series",
              "hide": false,
              "interval": "10s",
              "intervalFactor": 1,
              "legendFormat": "Sent",
              "metric": "network",
              "refId": "B",
              "step": 10
            }
          ],
          "thresholds": [],
          "timeFrom": null,
          "timeShift": null,
          "title": "Network I/O pressure",
          "tooltip": {
            "msResolution": false,
            "shared": true,
            "sort": 0,
            "value_type": "cumulative"
          },
          "transparent": false,
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "format": "Bps",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            },
            {
              "format": "Bps",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": false
            }
          ],
          "yaxis": {
            "align": false,
            "alignLevel": null
          }
        },
        {
          "aliasColors": {
            "max - istio-proxy": "#890f02",
            "max - master": "#bf1b00",
            "max - prometheus": "#bf1b00"
          },
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": "$${DS_PROMETHEUS}",
          "decimals": 2,
          "editable": false,
          "error": false,
          "fill": 0,
          "grid": {},
          "gridPos": {
            "h": 8,
            "w": 8,
            "x": 8,
            "y": 12
          },
          "id": 77,
          "isNew": true,
          "legend": {
            "alignAsTable": true,
            "avg": true,
            "current": true,
            "max": false,
            "min": false,
            "rightSide": false,
            "show": false,
            "sideWidth": 200,
            "sort": "current",
            "sortDesc": true,
            "total": false,
            "values": true
          },
          "lines": true,
          "linewidth": 2,
          "links": [],
          "nullPointMode": "connected",
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "avg(nginx_ingress_controller_nginx_process_resident_memory_bytes{controller_pod=~\"$pod\",controller_class=~\"$controller_class\",controller_namespace=~\"$namespace\"})",
              "format": "time_series",
              "instant": false,
              "interval": "10s",
              "intervalFactor": 1,
              "legendFormat": "nginx",
              "metric": "container_memory_usage:sort_desc",
              "refId": "A",
              "step": 10
            }
          ],
          "thresholds": [],
          "timeFrom": null,
          "timeShift": null,
          "title": "Average Memory Usage",
          "tooltip": {
            "msResolution": false,
            "shared": true,
            "sort": 2,
            "value_type": "cumulative"
          },
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "format": "bytes",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            },
            {
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": false
            }
          ],
          "yaxis": {
            "align": false,
            "alignLevel": null
          }
        },
        {
          "aliasColors": {
            "max - istio-proxy": "#890f02",
            "max - master": "#bf1b00"
          },
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": "$${DS_PROMETHEUS}",
          "decimals": 3,
          "editable": false,
          "error": false,
          "fill": 0,
          "grid": {},
          "gridPos": {
            "h": 8,
            "w": 8,
            "x": 16,
            "y": 12
          },
          "height": "",
          "id": 79,
          "isNew": true,
          "legend": {
            "alignAsTable": true,
            "avg": true,
            "current": true,
            "max": false,
            "min": false,
            "rightSide": false,
            "show": false,
            "sort": null,
            "sortDesc": null,
            "total": false,
            "values": true
          },
          "lines": true,
          "linewidth": 2,
          "links": [],
          "nullPointMode": "connected",
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "avg (rate (nginx_ingress_controller_nginx_process_cpu_seconds_total{controller_pod=~\"$pod\",controller_class=~\"$controller_class\",controller_namespace=~\"$namespace\"}[2m]))",
              "format": "time_series",
              "interval": "10s",
              "intervalFactor": 1,
              "legendFormat": "nginx",
              "metric": "container_cpu",
              "refId": "A",
              "step": 10
            }
          ],
          "thresholds": [
            {
              "colorMode": "critical",
              "fill": true,
              "line": true,
              "op": "gt"
            }
          ],
          "timeFrom": null,
          "timeShift": null,
          "title": "Average CPU Usage",
          "tooltip": {
            "msResolution": true,
            "shared": true,
            "sort": 2,
            "value_type": "cumulative"
          },
          "transparent": false,
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "format": "none",
              "label": "cores",
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            },
            {
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            }
          ],
          "yaxis": {
            "align": false,
            "alignLevel": null
          }
        },
        {
          "columns": [],
          "datasource": "$${DS_PROMETHEUS}",
          "fieldConfig": {
            "defaults": {
              "custom": {
                "align": "auto",
                "displayMode": "auto"
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green"
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              }
            },
            "overrides": [
              {
                "matcher": {
                  "id": "byName",
                  "options": "ingress"
                },
                "properties": [
                  {
                    "id": "displayName",
                    "value": "Ingress"
                  },
                  {
                    "id": "unit",
                    "value": "short"
                  },
                  {
                    "id": "decimals",
                    "value": 2
                  },
                  {
                    "id": "custom.align",
                    "value": "auto"
                  }
                ]
              },
              {
                "matcher": {
                  "id": "byName",
                  "options": "Value #C"
                },
                "properties": [
                  {
                    "id": "displayName",
                    "value": "P50 Latency"
                  },
                  {
                    "id": "unit",
                    "value": "dtdurations"
                  },
                  {
                    "id": "custom.align",
                    "value": "auto"
                  }
                ]
              },
              {
                "matcher": {
                  "id": "byName",
                  "options": "Value #D"
                },
                "properties": [
                  {
                    "id": "displayName",
                    "value": "P90 Latency"
                  },
                  {
                    "id": "unit",
                    "value": "dtdurations"
                  },
                  {
                    "id": "custom.align",
                    "value": "auto"
                  }
                ]
              },
              {
                "matcher": {
                  "id": "byName",
                  "options": "Value #E"
                },
                "properties": [
                  {
                    "id": "displayName",
                    "value": "P99 Latency"
                  },
                  {
                    "id": "unit",
                    "value": "dtdurations"
                  },
                  {
                    "id": "custom.align",
                    "value": "auto"
                  }
                ]
              },
              {
                "matcher": {
                  "id": "byName",
                  "options": "Value #F"
                },
                "properties": [
                  {
                    "id": "displayName",
                    "value": "IN"
                  },
                  {
                    "id": "unit",
                    "value": "Bps"
                  },
                  {
                    "id": "decimals",
                    "value": 2
                  },
                  {
                    "id": "custom.align",
                    "value": "auto"
                  },
                  {
                    "id": "thresholds",
                    "value": {
                      "mode": "absolute",
                      "steps": [
                        {
                          "color": "green"
                        },
                        {
                          "color": "red",
                          "value": 80
                        }
                      ]
                    }
                  }
                ]
              },
              {
                "matcher": {
                  "id": "byName",
                  "options": "Time"
                },
                "properties": [
                  {
                    "id": "unit",
                    "value": "short"
                  },
                  {
                    "id": "decimals",
                    "value": 2
                  },
                  {
                    "id": "custom.align",
                    "value": "auto"
                  }
                ]
              },
              {
                "matcher": {
                  "id": "byName",
                  "options": "Value #G"
                },
                "properties": [
                  {
                    "id": "displayName",
                    "value": "OUT"
                  },
                  {
                    "id": "unit",
                    "value": "Bps"
                  },
                  {
                    "id": "decimals",
                    "value": 1
                  },
                  {
                    "id": "custom.align",
                    "value": "auto"
                  }
                ]
              }
            ]
          },
          "fontSize": "100%",
          "gridPos": {
            "h": 8,
            "w": 24,
            "x": 0,
            "y": 20
          },
          "hideTimeOverride": false,
          "id": 75,
          "links": [],
          "options": {
            "footer": {
              "fields": "",
              "reducer": [
                "sum"
              ],
              "show": false
            },
            "frameIndex": 0,
            "showHeader": true
          },
          "pageSize": 7,
          "pluginVersion": "8.3.3",
          "repeatDirection": "h",
          "scroll": true,
          "showHeader": true,
          "sort": {
            "col": 1,
            "desc": true
          },
          "styles": [
            {
              "alias": "Ingress",
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "decimals": 2,
              "pattern": "ingress",
              "preserveFormat": false,
              "sanitize": false,
              "thresholds": [],
              "type": "string",
              "unit": "short"
            },
            {
              "alias": "Requests",
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "decimals": 2,
              "pattern": "Value #A",
              "thresholds": [
                ""
              ],
              "type": "number",
              "unit": "ops"
            },
            {
              "alias": "Errors",
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "decimals": 2,
              "pattern": "Value #B",
              "thresholds": [],
              "type": "number",
              "unit": "ops"
            },
            {
              "alias": "P50 Latency",
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "decimals": 0,
              "link": false,
              "pattern": "Value #C",
              "thresholds": [],
              "type": "number",
              "unit": "dtdurations"
            },
            {
              "alias": "P90 Latency",
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "decimals": 0,
              "pattern": "Value #D",
              "thresholds": [],
              "type": "number",
              "unit": "dtdurations"
            },
            {
              "alias": "P99 Latency",
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "decimals": 0,
              "pattern": "Value #E",
              "thresholds": [],
              "type": "number",
              "unit": "dtdurations"
            },
            {
              "alias": "IN",
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "decimals": 2,
              "pattern": "Value #F",
              "thresholds": [
                ""
              ],
              "type": "number",
              "unit": "Bps"
            },
            {
              "alias": "",
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "decimals": 2,
              "pattern": "Time",
              "thresholds": [],
              "type": "hidden",
              "unit": "short"
            },
            {
              "alias": "OUT",
              "colors": [
                "rgba(245, 54, 54, 0.9)",
                "rgba(237, 129, 40, 0.89)",
                "rgba(50, 172, 45, 0.97)"
              ],
              "dateFormat": "YYYY-MM-DD HH:mm:ss",
              "decimals": 2,
              "mappingType": 1,
              "pattern": "Value #G",
              "thresholds": [],
              "type": "number",
              "unit": "Bps"
            }
          ],
          "targets": [
            {
              "expr": "histogram_quantile(0.50, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{ingress!=\"\",controller_pod=~\"$pod\",controller_class=~\"$controller_class\",controller_namespace=~\"$namespace\",ingress=~\"$ingress\"}[2m])) by (le, ingress))",
              "format": "table",
              "hide": false,
              "instant": true,
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "{{ ingress }}",
              "refId": "C"
            },
            {
              "expr": "histogram_quantile(0.90, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{ingress!=\"\",controller_pod=~\"$pod\",controller_class=~\"$controller_class\",controller_namespace=~\"$namespace\",ingress=~\"$ingress\"}[2m])) by (le, ingress))",
              "format": "table",
              "hide": false,
              "instant": true,
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "{{ ingress }}",
              "refId": "D"
            },
            {
              "expr": "histogram_quantile(0.99, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{ingress!=\"\",controller_pod=~\"$pod\",controller_class=~\"$controller_class\",controller_namespace=~\"$namespace\",ingress=~\"$ingress\"}[2m])) by (le, ingress))",
              "format": "table",
              "hide": false,
              "instant": true,
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "{{ destination_service }}",
              "refId": "E"
            },
            {
              "expr": "sum(irate(nginx_ingress_controller_request_size_sum{ingress!=\"\",controller_pod=~\"$pod\",controller_class=~\"$controller_class\",controller_namespace=~\"$namespace\",ingress=~\"$ingress\"}[2m])) by (ingress)",
              "format": "table",
              "hide": false,
              "instant": true,
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "{{ ingress }}",
              "refId": "F"
            },
            {
              "expr": "sum(irate(nginx_ingress_controller_response_size_sum{ingress!=\"\",controller_pod=~\"$pod\",controller_class=~\"$controller_class\",controller_namespace=~\"$namespace\",ingress=~\"$ingress\"}[2m])) by (ingress)",
              "format": "table",
              "instant": true,
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "{{ ingress }}",
              "refId": "G"
            }
          ],
          "title": "Ingress Percentile Response Times and Transfer Rates",
          "transform": "table",
          "transformations": [
            {
              "id": "merge",
              "options": {
                "reducers": []
              }
            }
          ],
          "type": "table"
        },
        {
          "collapsed": false,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 28
          },
          "id": 33,
          "panels": [],
          "title": "Latency",
          "type": "row"
        },
        {
          "aliasColors": {},
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "decimals": 1,
          "description": "This graph can help assess and help us meet SLA requirements as far as the responsive time of our services.\n\nFor a more detailed latency graph broken out by ingress please open the closed tab at the bottom because it is very CPU intensive.",
          "fieldConfig": {
            "defaults": {
              "links": []
            },
            "overrides": []
          },
          "fill": 1,
          "fillGradient": 0,
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 0,
            "y": 29
          },
          "hiddenSeries": false,
          "id": 29,
          "legend": {
            "alignAsTable": true,
            "avg": true,
            "current": false,
            "hideEmpty": true,
            "hideZero": true,
            "max": true,
            "min": true,
            "rightSide": true,
            "show": true,
            "total": false,
            "values": true
          },
          "lines": true,
          "linewidth": 1,
          "links": [],
          "nullPointMode": "null",
          "options": {
            "alertThreshold": true
          },
          "percentage": false,
          "pluginVersion": "7.4.3",
          "pointradius": 2,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [
            {
              "$$hashKey": "object:294",
              "alias": "Average",
              "color": "#F2495C",
              "fill": 0,
              "points": true
            },
            {
              "$$hashKey": "object:316",
              "alias": "0.95",
              "color": "rgb(44, 0, 182)"
            },
            {
              "$$hashKey": "object:422",
              "alias": "0.9",
              "color": "#1F60C4"
            },
            {
              "$$hashKey": "object:430",
              "alias": "0.75",
              "color": "#8AB8FF",
              "fill": 1
            },
            {
              "$$hashKey": "object:440",
              "alias": "0.5",
              "color": "rgb(255, 255, 255)",
              "fill": 0
            },
            {
              "$$hashKey": "object:4144",
              "alias": "0.99",
              "color": "#8F3BB8",
              "fill": 0
            }
          ],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "histogram_quantile(\n  0.99,\n  sum by (le)(\n    rate(\n      nginx_ingress_controller_request_duration_seconds_bucket{\n        status!=\"404|500|304|499\",\n        controller_class=~\"$controller_class\",\n        ingress=~\"$ingress\",\n        namespace=~\"$namespace\",\n        controller_pod=~\"$pod\"\n      }[$__interval]\n    )\n  )\n)",
              "format": "time_series",
              "interval": "5m",
              "intervalFactor": 1,
              "legendFormat": "0.99",
              "refId": "A"
            },
            {
              "expr": "histogram_quantile(\n  0.95,\n  sum by (le)(\n    rate(\n      nginx_ingress_controller_request_duration_seconds_bucket{\n        status!=\"404|500|304|499\",\n        controller_class=~\"$controller_class\",\n        ingress=~\"$ingress\",\n        namespace=~\"$namespace\",\n        controller_pod=~\"$pod\"\n      }[$__interval]\n    )\n  )\n)",
              "format": "time_series",
              "hide": false,
              "interval": "5m",
              "intervalFactor": 1,
              "legendFormat": "0.95",
              "refId": "B"
            },
            {
              "expr": "histogram_quantile(\n  0.9,\n  sum by (le)(\n    rate(\n      nginx_ingress_controller_request_duration_seconds_bucket{\n        status!=\"404|500|304|499\",\n        controller_class=~\"$controller_class\",\n        ingress=~\"$ingress\",\n        namespace=~\"$namespace\",\n        controller_pod=~\"$pod\"\n      }[$__interval]\n    )\n  )\n)",
              "format": "time_series",
              "hide": false,
              "interval": "5m",
              "intervalFactor": 1,
              "legendFormat": "0.9",
              "refId": "C"
            },
            {
              "expr": "histogram_quantile(\n  0.5,\n  sum by (le)(\n    rate(\n      nginx_ingress_controller_request_duration_seconds_bucket{\n        status!=\"404|500|304|499\",\n        controller_class=~\"$controller_class\",\n        ingress=~\"$ingress\",\n        namespace=~\"$namespace\",\n        controller_pod=~\"$pod\"\n      }[$__interval]\n    )\n  )\n)",
              "format": "time_series",
              "hide": false,
              "interval": "5m",
              "intervalFactor": 1,
              "legendFormat": "0.5",
              "refId": "D"
            },
            {
              "expr": "histogram_quantile(\n  0.75,\n  sum by (le)(\n    rate(\n      nginx_ingress_controller_request_duration_seconds_bucket{\n        status!=\"404|500|304|499\",\n        controller_class=~\"$controller_class\",\n        ingress=~\"$ingress\",\n        namespace=~\"$namespace\",\n        controller_pod=~\"$pod\"\n      }[$__interval]\n    )\n  )\n)",
              "format": "time_series",
              "hide": false,
              "interval": "5m",
              "intervalFactor": 1,
              "legendFormat": "0.75",
              "refId": "E"
            },
            {
              "expr": "(\n\n(sum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"0.01\"\n}[$__interval]))\n* 0.01)\n\n+\n\n((sum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"0.1\"\n}[$__interval]))\n-\nsum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"0.01\"\n}[$__interval])))\n* 0.1)\n\n+\n\n((sum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"1\"\n}[$__interval]))\n-\nsum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"0.1\"\n}[$__interval])))\n* 1)\n\n+\n\n((sum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"10\"\n}[$__interval]))\n-\nsum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"1\"\n}[$__interval])))\n* 10 )\n\n+\n\n((sum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"30\"\n}[$__interval]))\n-\nsum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"10\"\n}[$__interval])))\n* 30 )\n\n+\n\n((sum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"60\"\n}[$__interval]))\n-\nsum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"30\"\n}[$__interval])))\n* 60 )\n\n+\n\n((sum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"+Inf\"\n}[$__interval]))\n-\nsum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"60\"\n}[$__interval])))\n* 120 )\n\n) / \n\nsum(increase(nginx_ingress_controller_request_duration_seconds_bucket{\n    status!=\"404|500|304\",\n    controller_class=~\"$controller_class\",\n    ingress=~\"$ingress\",\n    namespace=~\"$namespace\",\n    controller_pod=~\"$pod\",\n    le=\"+Inf\"\n}[$__interval]))\n",
              "format": "time_series",
              "hide": false,
              "interval": "5m",
              "intervalFactor": 1,
              "legendFormat": "Average",
              "refId": "F"
            }
          ],
          "thresholds": [],
          "timeRegions": [],
          "title": "Latency (Average Percentiles)",
          "tooltip": {
            "shared": true,
            "sort": 2,
            "value_type": "individual"
          },
          "type": "graph",
          "xaxis": {
            "mode": "time",
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "$$hashKey": "object:1035",
              "format": "s",
              "logBase": 1,
              "show": true
            },
            {
              "$$hashKey": "object:1036",
              "format": "short",
              "logBase": 1,
              "show": false
            }
          ],
          "yaxis": {
            "align": false
          }
        },
        {
          "cards": {},
          "color": {
            "cardColor": "#C4162A",
            "colorScale": "linear",
            "colorScheme": "interpolateTurbo",
            "exponent": 0.5,
            "mode": "spectrum"
          },
          "dataFormat": "tsbuckets",
          "description": "This graph can help assess and help us meet SLA requirements as far as the responsive time of our services.\n\nFor a more detailed latency graph broken out by ingress please open the closed tab at the bottom because it is very CPU intensive.",
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 12,
            "y": 29
          },
          "heatmap": {},
          "hideZeroBuckets": false,
          "highlightCards": true,
          "id": 27,
          "legend": {
            "show": true
          },
          "links": [],
          "pluginVersion": "7.4.3",
          "reverseYBuckets": false,
          "targets": [
            {
              "expr": "sum by (le)(\n  increase(\n    nginx_ingress_controller_request_duration_seconds_bucket{\n      status!=\"404\",status!=\"500\",\n      controller_class =~ \"$controller_class\",\n      namespace =~ \"$namespace\",\n      ingress =~ \"$ingress\"\n    }[$__interval]\n  )\n)",
              "format": "time_series",
              "hide": false,
              "interval": "5m",
              "intervalFactor": 1,
              "legendFormat": "{{le}}",
              "refId": "D"
            }
          ],
          "title": "Latency Heatmap",
          "tooltip": {
            "show": true,
            "showHistogram": false
          },
          "type": "heatmap",
          "xAxis": {
            "show": true
          },
          "yAxis": {
            "decimals": 0,
            "format": "s",
            "logBase": 1,
            "show": true
          },
          "yBucketBound": "auto"
        },
        {
          "collapsed": false,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 37
          },
          "id": 35,
          "panels": [],
          "title": "Connections",
          "type": "row"
        },
        {
          "aliasColors": {
            "New Connections": "purple"
          },
          "bars": true,
          "dashLength": 10,
          "dashes": false,
          "description": "NOTE: This does not work per ingress/namespace\n\nThis is the number of new connections opened by the controller",
          "fieldConfig": {
            "defaults": {
              "links": []
            },
            "overrides": []
          },
          "fill": 1,
          "fillGradient": 0,
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 0,
            "y": 38
          },
          "hiddenSeries": false,
          "id": 5,
          "legend": {
            "avg": false,
            "current": false,
            "max": false,
            "min": false,
            "show": false,
            "total": false,
            "values": false
          },
          "lines": false,
          "linewidth": 1,
          "links": [],
          "nullPointMode": "null",
          "options": {
            "alertThreshold": true
          },
          "paceLength": 10,
          "percentage": false,
          "pluginVersion": "7.4.3",
          "pointradius": 2,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "sum(increase(nginx_ingress_controller_nginx_process_connections{state=~\"active\",  controller_class=~\"$controller_class\", controller_pod=~\"$pod\"}[$__interval]))",
              "format": "time_series",
              "interval": "2m",
              "intervalFactor": 1,
              "legendFormat": "New Connections",
              "refId": "A"
            }
          ],
          "thresholds": [],
          "timeRegions": [],
          "title": "New Connections Opened (Controller / Ingress Pod)",
          "tooltip": {
            "shared": true,
            "sort": 0,
            "value_type": "individual"
          },
          "type": "graph",
          "xaxis": {
            "mode": "time",
            "show": false,
            "values": []
          },
          "yaxes": [
            {
              "$$hashKey": "object:3252",
              "format": "short",
              "logBase": 1,
              "show": true
            },
            {
              "$$hashKey": "object:3253",
              "format": "short",
              "logBase": 1,
              "show": false
            }
          ],
          "yaxis": {
            "align": false
          }
        },
        {
          "aliasColors": {
            "Connections": "rgb(255, 200, 4)"
          },
          "bars": true,
          "dashLength": 10,
          "dashes": false,
          "description": "NOTE: This does not work per ingress/namespace\n\nThe total number of connections opened to our ingresses.  If you have a CDN in front of our services, it is not unusual for this to be very low.  If/when we use something like websockets with a persistent connection this can/will be very high.",
          "fieldConfig": {
            "defaults": {
              "links": []
            },
            "overrides": []
          },
          "fill": 1,
          "fillGradient": 0,
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 12,
            "y": 38
          },
          "hiddenSeries": false,
          "id": 22,
          "legend": {
            "avg": false,
            "current": false,
            "max": false,
            "min": false,
            "show": false,
            "total": false,
            "values": false
          },
          "lines": false,
          "linewidth": 1,
          "links": [],
          "nullPointMode": "null",
          "options": {
            "alertThreshold": true
          },
          "paceLength": 10,
          "percentage": false,
          "pluginVersion": "7.4.3",
          "pointradius": 2,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "sum(avg_over_time(nginx_ingress_controller_nginx_process_connections{state=~\"active\", state=~\"active\",  controller_class=~\"$controller_class\", controller_pod=~\"$pod\"}[$__range]))",
              "format": "time_series",
              "intervalFactor": 1,
              "legendFormat": "Connections",
              "refId": "A"
            }
          ],
          "thresholds": [],
          "timeRegions": [],
          "title": "Total Connections Open (Controller / Ingress Pod)",
          "tooltip": {
            "shared": true,
            "sort": 0,
            "value_type": "individual"
          },
          "type": "graph",
          "xaxis": {
            "mode": "time",
            "show": false,
            "values": []
          },
          "yaxes": [
            {
              "$$hashKey": "object:3098",
              "format": "short",
              "logBase": 1,
              "show": true
            },
            {
              "$$hashKey": "object:3099",
              "format": "short",
              "logBase": 1,
              "show": false
            }
          ],
          "yaxis": {
            "align": false
          }
        },
        {
          "collapsed": true,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 46
          },
          "id": 24,
          "panels": [
            {
              "aliasColors": {},
              "bars": false,
              "dashLength": 10,
              "dashes": false,
              "description": "",
              "fieldConfig": {
                "defaults": {
                  "custom": {},
                  "links": []
                },
                "overrides": []
              },
              "fill": 1,
              "fillGradient": 0,
              "gridPos": {
                "h": 9,
                "w": 24,
                "x": 0,
                "y": 38
              },
              "hiddenSeries": false,
              "id": 25,
              "legend": {
                "alignAsTable": true,
                "avg": true,
                "current": false,
                "max": true,
                "min": true,
                "rightSide": true,
                "show": true,
                "total": false,
                "values": true
              },
              "lines": true,
              "linewidth": 1,
              "links": [],
              "nullPointMode": "null",
              "options": {
                "alertThreshold": true
              },
              "paceLength": 10,
              "percentage": false,
              "pluginVersion": "7.4.3",
              "pointradius": 2,
              "points": false,
              "renderer": "flot",
              "seriesOverrides": [],
              "spaceLength": 10,
              "stack": false,
              "steppedLine": false,
              "targets": [
                {
                  "expr": "sum(\n  rate(\n    nginx_ingress_controller_requests{status!~\"[4-5].*\", controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$${__range_s}s]\n      )\n   ) by (ingress)\n/ \n(\n  sum(\n    rate(\n      nginx_ingress_controller_requests{ controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$${__range_s}s]\n        )\n     ) by (ingress)\n     - \n  (\n  sum(\n    rate(\n      nginx_ingress_controller_requests{status=~\"404|499\", controller_class=~\"$controller_class\", ingress=~\"$ingress\",namespace=~\"$namespace\", controller_pod=~\"$pod\"}[$${__range_s}s]\n        )\n     ) by (ingress)\n  or vector(0)\n  )\n)",
                  "format": "time_series",
                  "interval": "",
                  "intervalFactor": 1,
                  "legendFormat": "{{ingress}}",
                  "refId": "A"
                }
              ],
              "thresholds": [],
              "timeRegions": [],
              "title": "Percentage of Success (non-2xx) - By Ingress",
              "tooltip": {
                "shared": true,
                "sort": 0,
                "value_type": "individual"
              },
              "type": "graph",
              "xaxis": {
                "mode": "time",
                "show": true,
                "values": []
              },
              "yaxes": [
                {
                  "$$hashKey": "object:108",
                  "format": "percentunit",
                  "logBase": 1,
                  "max": "1",
                  "min": "0",
                  "show": true
                },
                {
                  "$$hashKey": "object:109",
                  "format": "short",
                  "logBase": 1,
                  "show": false
                }
              ],
              "yaxis": {
                "align": false
              }
            },
            {
              "aliasColors": {},
              "bars": false,
              "dashLength": 10,
              "dashes": false,
              "fieldConfig": {
                "defaults": {
                  "custom": {},
                  "links": []
                },
                "overrides": []
              },
              "fill": 1,
              "fillGradient": 0,
              "gridPos": {
                "h": 13,
                "w": 24,
                "x": 0,
                "y": 47
              },
              "hiddenSeries": false,
              "id": 16,
              "legend": {
                "alignAsTable": true,
                "avg": true,
                "current": false,
                "max": true,
                "min": true,
                "rightSide": false,
                "show": true,
                "sort": "avg",
                "sortDesc": false,
                "total": false,
                "values": true
              },
              "lines": true,
              "linewidth": 1,
              "links": [],
              "nullPointMode": "null",
              "options": {
                "alertThreshold": true
              },
              "percentage": false,
              "pluginVersion": "7.4.3",
              "pointradius": 2,
              "points": false,
              "renderer": "flot",
              "seriesOverrides": [],
              "spaceLength": 10,
              "stack": false,
              "steppedLine": false,
              "targets": [
                {
                  "expr": "histogram_quantile(0.99, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{status!=\"404\",status!=\"500\", controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[5m])) by (le, ingress))",
                  "format": "time_series",
                  "intervalFactor": 1,
                  "legendFormat": "p99 {{ ingress }}",
                  "refId": "A"
                },
                {
                  "expr": "histogram_quantile(0.95, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{status!=\"404\",status!=\"500\", controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[5m])) by (le, ingress))",
                  "format": "time_series",
                  "intervalFactor": 1,
                  "legendFormat": "p95 {{ ingress }}",
                  "refId": "B"
                },
                {
                  "expr": "histogram_quantile(0.90, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{status!=\"404\",status!=\"500\", controller_class=~\"$controller_class\", ingress=~\"$ingress\", namespace=~\"$namespace\", controller_pod=~\"$pod\"}[5m])) by (le, ingress))",
                  "format": "time_series",
                  "intervalFactor": 1,
                  "legendFormat": "p90 {{ ingress }}",
                  "refId": "C"
                }
              ],
              "thresholds": [],
              "timeRegions": [],
              "title": "Latency (per ingress)",
              "tooltip": {
                "shared": true,
                "sort": 0,
                "value_type": "individual"
              },
              "type": "graph",
              "xaxis": {
                "mode": "time",
                "show": true,
                "values": []
              },
              "yaxes": [
                {
                  "format": "s",
                  "logBase": 1,
                  "show": true
                },
                {
                  "format": "short",
                  "logBase": 1,
                  "show": false
                }
              ],
              "yaxis": {
                "align": false
              }
            }
          ],
          "title": "CPU Intensive / Optional Graphs",
          "type": "row"
        }
      ],
      "refresh": "1m",
      "schemaVersion": 27,
      "style": "dark",
      "tags": [
        "ingress-nginx",
        "${name}",
        "lnrs-platform"
      ],
      "templating": {
        "list": [
          {
            "hide": 2,
            "includeAll": false,
            "label": "datasource",
            "multi": false,
            "name": "DS_PROMETHEUS",
            "options": [],
            "query": "prometheus",
            "refresh": 1,
            "regex": "",
            "skipUrlSync": false,
            "type": "datasource"
          },
          {
            "allValue": ".*",
            "current": {
              "selected": true,
              "text": "${ingress_class}",
              "value": "${ingress_class}"
            },
            "datasource": "$${DS_PROMETHEUS}",
            "definition": "label_values(nginx_ingress_controller_config_hash, controller_class) ",
            "hide": 2,
            "includeAll": false,
            "label": "Controller Class",
            "multi": true,
            "name": "controller_class",
            "options": [],
            "query": {
              "query": "label_values(nginx_ingress_controller_config_hash, controller_class) ",
              "refId": "prometheus-controller_class-Variable-Query"
            },
            "refresh": 1,
            "regex": "",
            "skipUrlSync": false,
            "sort": 1,
            "tagValuesQuery": "",
            "tagsQuery": "",
            "type": "query",
            "useTags": false
          },
          {
            "allValue": ".*",
            "current": {
              "selected": false,
              "text": "${namespace}",
              "value": "${namespace}"
            },
            "datasource": "$${DS_PROMETHEUS}",
            "definition": "label_values(nginx_ingress_controller_requests{ controller_class=~\"$controller_class\"},namespace)",
            "hide": 0,
            "includeAll": false,
            "label": "Namespace",
            "multi": true,
            "name": "namespace",
            "options": [],
            "query": {
              "query": "label_values(nginx_ingress_controller_requests{ controller_class=~\"$controller_class\"},namespace)",
              "refId": "prometheus-namespace-Variable-Query"
            },
            "refresh": 1,
            "regex": "",
            "skipUrlSync": false,
            "sort": 1,
            "tagValuesQuery": "",
            "tagsQuery": "",
            "type": "query",
            "useTags": false
          },
          {
            "current": {
              "selected": true,
              "text": [
                "All"
              ],
              "value": [
                "$__all"
              ]
            },
            "datasource": "$${DS_PROMETHEUS}",
            "definition": "label_values(nginx_ingress_controller_requests{namespace=~\"$namespace\",controller_class=~\"$controller_class\"}, ingress) ",
            "hide": 0,
            "includeAll": true,
            "label": "Ingress",
            "multi": true,
            "name": "ingress",
            "options": [],
            "query": {
              "query": "label_values(nginx_ingress_controller_requests{namespace=~\"$namespace\",controller_class=~\"$controller_class\"}, ingress) ",
              "refId": "prometheus-ingress-Variable-Query"
            },
            "refresh": 2,
            "regex": "",
            "skipUrlSync": false,
            "sort": 1,
            "tagValuesQuery": "",
            "tagsQuery": "",
            "type": "query",
            "useTags": false
          },
          {
            "allValue": ".*",
            "current": {
              "selected": true,
              "text": [
                "All"
              ],
              "value": [
                "$__all"
              ]
            },
            "datasource": "$${DS_PROMETHEUS}",
            "definition": "label_values(nginx_ingress_controller_config_hash{controller_class=~\"$controller_class\"}, controller_pod) ",
            "hide": 0,
            "includeAll": true,
            "label": "Ingress Pod",
            "multi": true,
            "name": "pod",
            "options": [],
            "query": {
              "query": "label_values(nginx_ingress_controller_config_hash{controller_class=~\"$controller_class\"}, controller_pod) ",
              "refId": "StandardVariableQuery"
            },
            "refresh": 1,
            "regex": "",
            "skipUrlSync": false,
            "sort": 1,
            "tagValuesQuery": "",
            "tagsQuery": "",
            "type": "query",
            "useTags": false
          }
        ]
      },
      "time": {
        "from": "now-3h",
        "to": "now"
      },
      "timepicker": {
        "refresh_intervals": [
          "10s",
          "30s",
          "1m",
          "5m",
          "15m",
          "30m",
          "1h",
          "2h",
          "1d"
        ],
        "time_options": [
          "5m",
          "15m",
          "1h",
          "6h",
          "12h",
          "24h",
          "2d",
          "7d",
          "30d"
        ]
      },
      "timezone": "",
      "title": "Ingress Nginx - ${title}",
      "description": "Ingress Nginx (${title}) Controller via Prometheus Metrics Dashboard.",
      "uid": "k8s-nginx-${name}"
    }

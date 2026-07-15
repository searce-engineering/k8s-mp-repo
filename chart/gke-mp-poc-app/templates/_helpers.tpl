{{/*
Expand the name of the chart.
*/}}
{{- define "gke-mp-poc-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

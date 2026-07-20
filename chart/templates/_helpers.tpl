{{/*
  _helpers.tpl
  ─────────────────────────────────────────────────────────────────────────────
  Named templates (partials) shared across all chart templates.
  Every define block is callable via {{ include "gcp-mp-poc-k8s.<name>" . }}

  Helm rules to keep in mind:
    • Names are global — always prefix with the chart name to avoid collisions
      if this chart is used as a dependency inside a larger chart.
    • Use {{- ... -}} to strip surrounding whitespace so indentation stays
      predictable when you pipe through | nindent N in callers.
    • trunc 63 | trimSuffix "-" is required because Kubernetes label values
      and resource names must be ≤ 63 characters.
*/}}


{{/*
  gcp-mp-poc-k8s.name
  Returns the chart name, allowing an override via .Values.nameOverride.
  Used as the base for the app.kubernetes.io/name label.
*/}}
{{- define "gcp-mp-poc-k8s.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
  gcp-mp-poc-k8s.fullname
  Returns the fully-qualified resource name used for Deployment, Service, etc.
  Logic:
    1. If .Values.fullnameOverride is set → use that directly.
    2. Otherwise combine .Release.Name + chart name, but skip the chart name
       if .Release.Name already contains it (avoids "myapp-myapp" duplication
       when `helm install myapp ./chart`).
  Callers: deployment.yaml, service.yaml
*/}}
{{- define "gcp-mp-poc-k8s.fullname" -}}
{{- if .Values.fullnameOverride }}
  {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
  {{- $name := default .Chart.Name .Values.nameOverride }}
  {{- if contains $name .Release.Name }}
    {{- .Release.Name | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
  {{- end }}
{{- end }}
{{- end }}


{{/*
  gcp-mp-poc-k8s.chart
  Returns the "chart label" value: <chart-name>-<chart-version>.
  The + → _ replacement makes SemVer build metadata (e.g. 1.0.0+build1)
  safe for use as a Kubernetes label value.
  Callers: gcp-mp-poc-k8s.labels (indirectly on all resources)
*/}}
{{- define "gcp-mp-poc-k8s.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
  gcp-mp-poc-k8s.labels
  Full set of recommended Kubernetes labels applied to every resource.
  Includes both selector labels (immutable) and informational labels.

  DO NOT put mutable / environment-specific values here because these
  labels are also used on the Deployment spec.selector — once a Deployment
  is created the selector is immutable.

  Callers: deployment.yaml, service.yaml, serviceaccount.yaml,
           secret.yaml, application.yaml
*/}}
{{- define "gcp-mp-poc-k8s.labels" -}}
helm.sh/chart: {{ include "gcp-mp-poc-k8s.chart" . }}
{{ include "gcp-mp-poc-k8s.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
  gcp-mp-poc-k8s.selectorLabels
  Minimal immutable labels used in:
    • spec.selector.matchLabels  (Deployment — must never change after creation)
    • spec.template.metadata.labels  (must be a superset of matchLabels)
    • Service spec.selector  (routes traffic to matching pods)

  Keep this set small and stable — adding a label here on an upgrade will
  break the rollout because Kubernetes rejects changes to Deployment selectors.
*/}}
{{- define "gcp-mp-poc-k8s.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gcp-mp-poc-k8s.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
  gcp-mp-poc-k8s.serviceAccountName
  Returns the ServiceAccount name the Deployment should use.
  Logic:
    • If serviceAccount.create is true  → use serviceAccount.name (or the
      fullname as a fallback if name is blank).
    • If serviceAccount.create is false → use serviceAccount.name as-is,
      assuming the SA already exists in the cluster (useful when an operator
      pre-creates the SA with specific RBAC bindings).

  Callers: deployment.yaml (spec.template.spec.serviceAccountName)
           serviceaccount.yaml (metadata.name, guarded by .Values.serviceAccount.create)
*/}}
{{- define "gcp-mp-poc-k8s.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
  {{- default (include "gcp-mp-poc-k8s.fullname" .) .Values.serviceAccount.name }}
{{- else }}
  {{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

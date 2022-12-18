{{- define "metrics" -}}
endpoints:
    - interval: 5s
      path: {{ .Values.target }}
      port: http
selector:
    matchLabels:
      app.kubernetes.io/name: {{ .Values.nameService }}
{{- end }}
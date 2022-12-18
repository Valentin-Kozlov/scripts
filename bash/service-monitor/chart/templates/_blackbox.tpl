{{- define "blackbox" -}}
endpoints:
    - interval: 1m
      metricRelabelings:
        - sourceLabels:
            - __address__
          targetLabel: __param_target
        - sourceLabels:
            - __param_target
          targetLabel: instance
        - replacement: '{{ .Values.nameService }}:9115'
          targetLabel: __address__
        - replacement: {{ .Values.nameService }}
          targetLabel: job
      params:
        module:
          - {{ .Values.blackboxtype }}
        target:
          - {{ .Values.target }}
      path: /probe
      port: http
      scheme: http
      scrapeTimeout: 5s
jobLabel: {{ .Values.nameService }}
selector:
    matchLabels:
      app: prometheus-blackbox-exporter
      group: prometheus
{{- end }}
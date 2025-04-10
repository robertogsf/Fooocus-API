FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime

ENV TZ=Asia/Shanghai

WORKDIR /app

COPY . /app

RUN pip install --no-cache-dir -r requirements.txt

RUN pip install --no-cache-dir opencv-python-headless -i https://pypi.org/simple

# Crear directorio temporal para los archivos de actividad
RUN mkdir -p /tmp && \
    touch /tmp/had_request && \
    touch /tmp/last_activity && \
    chmod 777 /tmp/had_request && \
    chmod 777 /tmp/last_activity

EXPOSE 8888

CMD ["/app/monitor.sh"]

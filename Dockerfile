FROM python:3.8
LABEL maintainer="Shubham Kandwal"

COPY /analytics/. /app
WORKDIR /app

RUN pip install -r requirements.txt

EXPOSE 5153
CMD ["python", "app.py"]
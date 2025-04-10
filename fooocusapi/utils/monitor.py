import time
import os
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

class ActivityMonitorMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Actualizar timestamp antes de procesar la solicitud
        update_activity_timestamp()
        # Continuar con el siguiente middleware o endpoint
        response = await call_next(request)
        return response

def update_activity_timestamp():
    try:
        with open('/tmp/had_request', 'w') as f:
            f.write('true')
        
        timestamp = int(time.time())
        with open('/tmp/last_activity', 'w') as f:
            f.write(str(timestamp))
            
    except Exception as e:
        print(f"Error al actualizar timestamp: {e}")
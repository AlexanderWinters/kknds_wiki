# Gunicorn configuration file
bind = "0.0.0.0:3300"
workers = 3  # Recommended workers = (2 x NUM_CORES) + 1
timeout = 120

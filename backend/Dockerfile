FROM node:18-alpine
WORKDIR /usr/src/app
COPY package*.json ./
# Use `npm ci` when a lockfile exists, otherwise fall back to `npm install`
RUN if [ -f package-lock.json ]; then \
			npm ci --only=production; \
		else \
			npm install --omit=dev --no-audit --no-fund; \
		fi
COPY . .
EXPOSE 3001
CMD ["node", "src/index.js"]

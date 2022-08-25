FROM node:16.17.0
COPY . .
RUN yarn install
CMD yarn h-node 
EXPOSE 8545
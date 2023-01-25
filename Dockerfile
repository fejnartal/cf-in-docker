FROM alpine AS third-party-deps
RUN apk --update add git curl --no-cache
RUN git clone https://github.com/cloudfoundry/bosh-deployment
RUN git clone https://github.com/cloudfoundry/cf-deployment
RUN curl -o bosh -L https://github.com/cloudfoundry/bosh-cli/releases/download/v7.1.2/bosh-cli-7.1.2-linux-amd64 && chmod +x bosh
RUN curl -o credhub.tgz -L https://github.com/cloudfoundry/credhub-cli/releases/download/2.9.10/credhub-linux-2.9.10.tgz && tar xvf credhub.tgz && chmod +x credhub

FROM ubuntu:bionic as dind-ubuntu
COPY ./install-dind.sh /install-dind.sh
RUN chmod +x /install-dind.sh && /install-dind.sh
VOLUME /var/lib/docker
EXPOSE 2375 2376
CMD []

FROM dind-ubuntu
COPY --from=third-party-deps credhub /usr/local/bin/credhub
COPY --from=third-party-deps bosh /usr/local/bin/bosh
COPY --from=third-party-deps bosh-deployment/ /bosh-deployment
COPY --from=third-party-deps cf-deployment/ cf-deployment
COPY ./add-route /usr/local/bin/add-route
COPY ./ /bosh-in-docker
ENTRYPOINT /bosh-in-docker/create-env.sh

FROM public.ecr.aws/amazonlinux/amazonlinux:2 as base
ARG AWSCLI_VERSION=2.4.1
ENV AWSCLI_VERSION=${AWSCLI_VERSION}

FROM base as base-amd64
ENV AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64-$AWSCLI_VERSION.zip"
ENV SSM_MANAGER_URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
ENV JP_URL="https://github.com/jmespath/jp/releases/latest/download/jp-linux-amd64"
FROM base as base-arm64
ENV AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64-$AWSCLI_VERSION.zip"
ENV SSM_MANAGER_URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_arm64/session-manager-plugin.rpm"
ENV JP_URL="https://github.com/jmespath/jp/releases/latest/download/jp-linux-arm64"

FROM base-${TARGETARCH} AS installer
RUN echo "$AWS_CLI_URL"
RUN yum update -y \
  && yum install -y unzip \
  && curl "$AWS_CLI_URL" -o awscli.zip \
  && unzip awscli.zip \
  # The --bin-dir is specified so that we can copy the
  # entire bin directory from the installer stage into
  # into /usr/local/bin of the final stage without
  # accidentally copying over any other executables that
  # may be present in /usr/local/bin of the installer stage.
  && ./aws/install --bin-dir /aws-cli-bin/

FROM base-${TARGETARCH}
RUN yum update -y \
  && yum install -y less groff \
  && yum install -y jq \
  && yum install -y "$SSM_MANAGER_URL" \
  && yum install -y shadow-utils \
  && yum clean all
RUN curl -L "$JP_URL" -o /usr/local/bin/jp \
  && chmod +x /usr/local/bin/jp
COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /aws-cli-bin/ /usr/local/bin/

RUN useradd workshop-user
USER workshop-user
WORKDIR /home/workshop-user
ADD . environment/aws-cli-workshop/
RUN mkdir -p /home/workshop-user/.aws/cli; ln -s /home/workshop-user/environment/aws-cli-workshop/assets/alias /home/workshop-user/.aws/cli/alias
ENV PATH="${PATH}:/home/workshop-user/environment/aws-cli-workshop/scripts"

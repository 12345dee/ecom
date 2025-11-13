#!/bin/bash
set -euo pipefail
# Usage: ecs_deploy_bluegreen.sh <cluster> <service_active> <service_idle> <task_def_family> <image_full> <tg_active_arn> <tg_idle_arn> <alb_listener_arn> <region>
CLUSTER="$1"
SERVICE_ACTIVE="$2"
SERVICE_IDLE="$3"
TASK_FAMILY="$4"
IMAGE="$5"
TG_ACTIVE="$6"
TG_IDLE="$7"
ALB_LISTENER="$8"
REGION="$9"
echo "Deploying to ECS cluster ${CLUSTER}"
CURRENT_TD_JSON=$(aws ecs describe-task-definition --task-definition ${TASK_FAMILY} --region ${REGION})
NEW_TD_JSON=$(echo "$CURRENT_TD_JSON" | jq --arg IMAGE "$IMAGE" '.taskDefinition | {family: .family, containerDefinitions: (.containerDefinitions | map(.image=$IMAGE)), cpu:.cpu, memory:.memory, networkMode:.networkMode, requiresCompatibilities:.requiresCompatibilities, executionRoleArn:.executionRoleArn, taskRoleArn:.taskRoleArn}')
NEW_REG_OUT=$(aws ecs register-task-definition --cli-input-json "$(echo $NEW_TD_JSON | jq -c .)" --region ${REGION})
NEW_TASK_DEF_ARN=$(echo "$NEW_REG_OUT" | jq -r '.taskDefinition.taskDefinitionArn')
aws ecs update-service --cluster ${CLUSTER} --service ${SERVICE_IDLE} --task-definition ${NEW_TASK_DEF_ARN} --desired-count 1 --region ${REGION}
for i in {1..30}; do
  sleep 6
  HEALTH_COUNT=$(aws elbv2 describe-target-health --target-group-arn ${TG_IDLE} --region ${REGION} | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State=="healthy")] | length')
  echo "Healthy targets: $HEALTH_COUNT"
  if [ "$HEALTH_COUNT" -gt 0 ]; then
    echo "Idle service healthy"
    break
  fi
done
aws elbv2 modify-listener --listener-arn ${ALB_LISTENER} --default-actions Type=forward,TargetGroupArn=${TG_IDLE} --region ${REGION}
aws ecs update-service --cluster ${CLUSTER} --service ${SERVICE_ACTIVE} --desired-count 0 --region ${REGION}
echo "Deployment complete. New task def: ${NEW_TASK_DEF_ARN}"

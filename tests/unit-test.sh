#!/bin/bash
set -x

image_name=${1:? $(basename $0) IMAGE_NAME VERSION needed}
VERSION=${2:-latest}
namespace=elasticsearch
elasticsearch=elasticsearch
export VERSION

ret=0
echo "Check tests/docker-compose.yml config"
docker-compose -p ${namespace} config
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] docker-compose -p ${namespace} config"
else
  echo "[FAILED] docker-compose -p ${namespace} config"
  ret=1
fi
echo "Check elasticsearch installed"
docker-compose -p ${namespace} run --name "test-elasticsearch" --rm $elasticsearch ls -l /opt/
test_result=$?
if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] elasticsearch installed"
else
  echo "[FAILED] elasticsearch installed"
  ret=1
fi

# test a small nginx config
echo "Check elasticsearch running"

# setup test
echo "# setup env test:"
test_compose=docker-compose.yml
elasticsearch=elasticsearch
test_config=elasticsearch-test.sh
docker-compose -p ${namespace} -f $test_compose up -d --no-build $elasticsearch
docker-compose -p ${namespace} -f $test_compose ps $elasticsearch
container=$(docker-compose -p ${namespace}  -f $test_compose ps -q $elasticsearch)
echo docker cp $test_config ${container}:/opt
docker cp $test_config ${container}:/opt

# run test
echo "# run test:"
docker-compose -p ${namespace}  -f $test_compose exec -T $elasticsearch /bin/bash -c "/opt/$test_config"
test_result=$?

# teardown
echo "# teardown:"
docker-compose -p ${namespace}  -f $test_compose stop
docker-compose -p ${namespace}  -f $test_compose rm -fv

if [ "$test_result" -eq 0 ] ; then
  echo "[PASSED] elasticsearch url check [$test_config]"
else
  echo "[FAILED] elasticsearch url check [$test_config]"
  ret=1
fi

exit $ret

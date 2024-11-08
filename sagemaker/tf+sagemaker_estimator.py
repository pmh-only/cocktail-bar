from sagemaker.tensorflow import TensorFlow

mnist_estimator = TensorFlow(
    entry_point='mnist-2.py',
    role=role,
    instance_count=2,
    instance_type='ml.c5.xlarge',
    framework_version='2.1.0',
    py_version='py3',
    distribution={'parameter_server': {'enabled': True}}
)

training_data_uri = 's3://sagemaker-example-data-tf/mnist'
mnist_estimator.fit(training_data_uri)
predictor = mnist_estimator.deploy(initial_instance_count=1, instance_type='ml.m4.xlarge')


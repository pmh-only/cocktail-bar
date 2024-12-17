from sagemaker.pytorch import PyTorch

estimator = PyTorch(
    entry_point="pytorch+sagemaker_model.py",
    role=role,
    py_version="py38",
      framework_version="1.11.0",
    instance_count=2,
    instance_type="ml.c5.2xlarge",
    hyperparameters={"epochs": 1, "backend": "gloo"},
)

estimator.fit({"training": inputs})

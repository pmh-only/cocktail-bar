from locust import HttpUser, task
from random import Random
import uuid
import time

class AccountAppUser(HttpUser):
    user_ids = []
    random = Random()

    @task
    def landing_page(self):
        time.sleep(self.random.random())
        self.client.get("/")
        
    @task(3)
    def user_get(self):
        time.sleep(self.random.random())
        user_id = self.user_ids[self.random.randint(0, len(self.user_ids) - 1)]
        self.client.get("/users?id=" + user_id)

    @task(2)
    def user_post(self):
        time.sleep(self.random.random())
        user_id = str(uuid.uuid4())
        self.user_ids.append(user_id)
        self.client.post('/users', json={"id": user_id})

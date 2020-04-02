# Introduction

Woolworths Online is an online shopping service provided by the Woolworths company. The Woolworths company hires you to design a small database to store the information about its online shopping service. You’re given the following requirements:

- A customer is identified by his/her email address, and for each customer, we want to record his/her name, phone number, and address. The address is composed of street and suburb.

- A warehouse is identified by its warehouse ID and we also record its contact number.

- A commodity is identified by its commodity ID, and we also need to know the name, price, and supplier. A commodity may have multiple suppliers. A commodity must be stored in at least one warehouse and a warehouse must store at least one commodity. The stock level of a commodity in a warehouse is needed.

- An order is uniquely identified by its order ID. An order must be created by one customer and a customer must have created at least one order. The time of an order created is needed. An order is composed of at least one commodity and the quantity of each ordered commodity is required. Some commodities may not be included in any orders. We also want to know the total amount of an order.

- An order is sent to exactly one warehouse and a warehouse can process multiple orders.

- A staff is identified by his/her staff ID. The name, birth date, phone number is also needed. A staff is either a manager or a team member. A team member must be supervised by exactly one manager and a manager can supervise multiple team members.

- There should be at least one staff works in a warehouse, and a staff should work in exactly one warehouse. There must be exactly one manager at a warehouse and a manager must manage exactly one warehouse.

Question 1: Draw an ER diagram to represent this scenario, and clearly state the assumptions you make if any.

Question 2: Convert your ER-diagram from Question 1 into a relational model.



# Solution:

Question 1:

![Screen Shot 2020-04-02 at 5.56.33 pm](https://i.imgur.com/s6fNCKz.png)

Question 2:

![Screen Shot 2020-04-02 at 5.55.29 pm](https://i.imgur.com/91tgQtw.png)




-- Create an index on the 'city' column in the 'ServicePoint' table
CREATE INDEX ServicePointCity ON ServicePoint(city);

-- Create an index on the 'TimeDelivered' column in the 'Deliver_To' table
CREATE INDEX DeliverTime ON Deliver_To(TimeDelivered);

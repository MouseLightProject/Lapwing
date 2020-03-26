function motion_correct(self)

self.hourglass();
self.model.motion_correct();
self.model_data_changed();
self.unhourglass();

end

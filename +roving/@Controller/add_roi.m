function add_roi(self,r_border)

% figure out what the label for this ROI will be
i=self.card_birth_roi_next;
while 1
  tentative_label=roving.alphabetic_label_from_int(i);
  if ~self.model.label_in_use(tentative_label)
    label_this=tentative_label;
    break;
  end
  i=i+1;
end

% Add the ROI to the model
self.model.add_roi(r_border,label_this);

% Update the view
self.view.add_roi(r_border,label_this);

% Update the cardinality of the next ROI to be born.
self.card_birth_roi_next=self.card_birth_roi_next+1;

end

function newly_opened_file(self)
    % Called after a new file has been opened in the model.  Updates the view
    % appropriately, and initializes the view state as appropriate for a newly
    % opened file.

    % Update the model state
    self.model.reset_state_for_newly_opened_file() ;

    % Update the view HG objects to match the model & view state
    self.model_changed();
end

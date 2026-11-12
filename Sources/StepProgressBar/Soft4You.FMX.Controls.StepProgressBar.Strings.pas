unit Soft4You.FMX.Controls.StepProgressBar.Strings;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YStepProgressBar - progress indicator made of steps along a line
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

resourcestring
  // Captions of the steps of a new control.
  S_STEP_START_CAPTION = 'Start';
  S_STEP_INTERMEDIATE_CAPTION = 'Step';
  S_STEP_END_CAPTION = 'End';

  // Errors of TS4YStepList.
  S_STEP_INDEX_NOT_ALLOWED = 'Step index %d is not allowed: the first and the last steps cannot be removed or ' +
    'moved, and the indexes allowed here are from %d to %d.';
  S_STEP_FIXED_STEP_FREED = 'The first and the last steps of a TS4YStepProgressBar cannot be removed.';
  S_STEP_ADDED_OUTSIDE_LIST = 'The steps of a TS4YStepProgressBar are added with Steps.Add or Steps.Insert.';

  // Editor of the steps in the IDE.
  S_STEP_EDITOR_CAPTION = 'Editing %s.Steps';
  S_STEP_EDITOR_ADD = '&Add';
  S_STEP_EDITOR_INSERT = '&Insert';
  S_STEP_EDITOR_DELETE = '&Delete';
  S_STEP_EDITOR_MOVE_UP = 'Move &up';
  S_STEP_EDITOR_MOVE_DOWN = 'Move dow&n';
  // Command of the context menu of the control in the form designer.
  S_STEP_EDITOR_VERB = 'Edit Steps...';

implementation

end.

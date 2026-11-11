unit Soft4You.FMX.Controls.StepProgressBar.Types;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YStepProgressBar - types of the step progress indicator
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

interface

uses
  System.Types,
  FMX.Graphics;

type
  /// <summary>
  /// Side of the line where a TS4YStepProgressBar shows the captions and the descriptions of the steps.
  /// </summary>
  /// <remarks>
  /// slpNone: no caption and no description.
  /// slpBefore: above the line when it is horizontal, on its left when it is vertical.
  /// slpAfter: below the line when it is horizontal, on its right when it is vertical.
  /// </remarks>
  TS4YStepLabelPosition = (
    slpNone,
    slpBefore,
    slpAfter
  );

  /// <summary>
  /// State in which a step of a TS4YStepProgressBar is drawn.
  /// </summary>
  /// <remarks>
  /// sstCompleted: a step before the current one.
  /// sstCurrent: the current step.
  /// sstPending: a step after the current one.
  /// sstFailed: a step whose Failed property is True, wherever it is.
  /// </remarks>
  TS4YStepState = (
    sstCompleted,
    sstCurrent,
    sstPending,
    sstFailed
  );

  /// <summary>
  /// What a marker of a TS4YStepProgressBar shows inside its circle.
  /// </summary>
  /// <remarks>
  /// smcNone: nothing.
  /// smcNumber: the number of the step, starting from 1.
  /// smcImage: an image of the Images list of the control.
  /// </remarks>
  TS4YStepMarkerContent = (
    smcNone,
    smcNumber,
    smcImage
  );

  /// <summary>
  /// A brush of a marker that can come from the style.
  /// </summary>
  /// <remarks>
  /// smbFill: the fill of the marker.
  /// smbStroke: the border of the marker.
  /// </remarks>
  TS4YStepMarkerStyledBrush = (
    smbFill,
    smbStroke
  );

  /// <summary>
  /// The brushes of a marker that come from the style instead of the Fill and Stroke properties.
  /// </summary>
  TS4YStepMarkerStyledBrushes = set of TS4YStepMarkerStyledBrush;

  /// <summary>
  /// A brush of the line that can come from the style.
  /// </summary>
  /// <remarks>
  /// slbCompleted: the part of the line already covered by the progress.
  /// slbPending: the part of the line still to cover, or the whole line when the progress is not highlighted.
  /// </remarks>
  TS4YStepLineStyledBrush = (
    slbCompleted,
    slbPending
  );

  /// <summary>
  /// The brushes of the line that come from the style instead of the CompletedFill and PendingFill properties.
  /// </summary>
  TS4YStepLineStyledBrushes = set of TS4YStepLineStyledBrush;

  /// <summary>
  /// A way in which the user can change the current step of a TS4YStepProgressBar.
  /// </summary>
  /// <remarks>
  /// stiClickMarker: a click on the marker of a step makes it the current one.
  /// stiClickLabel: a click on the caption or the description of a step makes it the current one.
  /// stiHandCursor: the mouse pointer becomes a hand over the steps that a click can select.
  /// stiKeyboard: when the control has the focus, the arrow keys move to the previous or the next step, Home and End to the first or the last one.
  /// </remarks>
  TS4YStepInteraction = (
    stiClickMarker,
    stiClickLabel,
    stiHandCursor,
    stiKeyboard
  );

  /// <summary>
  /// The ways in which the user can change the current step of a TS4YStepProgressBar.
  /// </summary>
  TS4YStepInteractions = set of TS4YStepInteraction;

  /// <summary>
  /// Event fired before the current step of a TS4YStepProgressBar changes.
  /// </summary>
  /// <remarks>
  /// ANewStep is the index of the step that is going to become the current one. Setting Allow to False keeps the current step.
  /// </remarks>
  TS4YStepChangingEvent = procedure(Sender: TObject; const ANewStep: Integer; var Allow: Boolean) of object;

  /// <summary>
  /// Event fired before a marker of a TS4YStepProgressBar is drawn.
  /// </summary>
  /// <remarks>
  /// ARect is the area of the marker, MarkerSize x MarkerSize, AStepIndex the index of the step and AState the state it is drawn in.
  /// Setting Handled to True means the marker has been drawn by the event, and the control does not draw it.
  /// </remarks>
  TS4YStepDrawMarkerEvent = procedure(Sender: TObject; const ACanvas: TCanvas; const ARect: TRectF;
    const AStepIndex: Integer; const AState: TS4YStepState; var Handled: Boolean) of object;

implementation

end.

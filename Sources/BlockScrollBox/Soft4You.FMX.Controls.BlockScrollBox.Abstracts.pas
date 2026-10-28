unit Soft4You.FMX.Controls.BlockScrollBox.Abstracts;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YBlockScrollBox - scroll box with the CSS block flow
  Copyright (c) 2026 Carlo Marona (Soft4You)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{
  Interfaces between the block flow and its children. A control that implements
  IS4YBlockFlowChild takes part in the flow with its own rules (the flexbox
  does); the parent of the children in the flow implements IS4YBlockFlowContainer,
  so that a child knows it is in the flow without knowing the class of the box.
}

interface

type
  /// <summary>Marks the parent of the children in the block flow: the flow decides their position and width.</summary>
  IS4YBlockFlowContainer = interface
    ['{46432984-526D-4974-B167-D78935A6C7AB}']
  end;

  /// <summary>A child that takes part in the block flow with its own rules.</summary>
  IS4YBlockFlowChild = interface
    ['{DE5189D8-4F76-4488-8333-9411AD63EDB9}']
    /// <summary>True if the width of the child is automatic (like width: auto in CSS): the flow gives it with SetFlowBounds.</summary>
    function GetFlowAutoWidth: Boolean;
    /// <summary>The right edge of the content of the child after its layout, from the left of the child: more than the width when the content overflows (like the scrollable overflow in CSS).</summary>
    function GetFlowOverflowWidth: Single;
    /// <summary>Places a child with an automatic width: the position and the width given by the flow. The child then sets its own height.</summary>
    procedure SetFlowBounds(ALeft, ATop, AWidth: Single);
  end;

implementation

end.

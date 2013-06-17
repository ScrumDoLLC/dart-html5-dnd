part of html5_sortable;

/**
 * Manages a group of sortables and their options and event listeners.
 * 
 * A sortable element is at the same time a draggable and a dropzone element. 
 * Sortable elements can be dragged to either other sortables or to dropzones. 
 * A sortable can accept other draggable elements that are not sortables.
 */
class SortableGroup extends DraggableGroup {
  // -------------------
  // Sortable Options
  // -------------------
  /**
   * CSS class set on the placeholder element. Default is 'dnd-placeholder'. If 
   * null, no css class is added.
   */
  String placeholderClass = 'dnd-placeholder';
  
  /**
   * If true, forces the placeholder to have the computed size of the dragged
   * element. Default is true.
   * 
   * **Note:** Placeholders should have at least the size of the dragged 
   * element. If smaller, the mouse might already be outside of the placeholder 
   * when the drag is started. This leads to a bad user experience.
   */
  bool forcePlaceholderSize = true;
  
  /**
   * Must be set to true for sortable grids. This ensures that different sized
   * items in grids are handled correctly.
   */
  bool isGrid = false;
  
  // -------------------
  // Sortable Events
  // -------------------
  StreamController<SortableEvent> _onSortUpdate;
  
  /**
   * Returns the stream of sort update events. This event is triggered when the 
   * user stopped sorting and the DOM position has changed. If the user aborts 
   * the drag or drops the element at the same position, no event is fired.
   */
  Stream<SortableEvent> get onSortUpdate {
    if (_onSortUpdate == null) {
      _onSortUpdate = new StreamController<SortableEvent>.broadcast(sync: true, 
          onCancel: () => _onSortUpdate = null);
    }
    return _onSortUpdate.stream;
  }
  
  // -------------------
  // Dropzone Options (forwarded to _dropzoneGroup)
  // -------------------
  Set<DraggableGroup> get accept => _dropzoneGroup.accept;
  set accept(Set<DraggableGroup> accept) => _dropzoneGroup.accept = accept;
  
  // -------------------
  // Private Properties
  // -------------------
  final DropzoneGroup _dropzoneGroup;
  
  /// Subscription on dropzone dragEnter (one for the entire sortable group).
  StreamSubscription _dragEnterSub;
  /// Subscription on dropzone dragStart (one for the entire sortable group).
  StreamSubscription _dragStartSub;
  
  /**
   * Constructor.
   * 
   * If [handle] is set to a value other than null, it is used as query String
   * to find a subelement of [element]. The drag is then restricted that 
   * subelement. 
   */
  SortableGroup({String handle}) :
    _dropzoneGroup = new DropzoneGroup(),
    super(handle: handle) {
    // Disable overClass by default for sortable as we're usually only over the 
    // placeholder and not over a dropzone. Same for draggingClass as the 
    // dragged element is replaced by the placeholder and thus not visible.
    overClass = null;
    draggingClass = null;
  }
  
  /**
   * Installs sortable behaviour on [element] and registers it in this group.
   */
  void install(Element element) {
    _logger.finest('installing sortable');
    super.install(element);
    
    // Sortable elements are at the same time draggables (superclass) and dropzones.
    _dropzoneGroup.install(element);
    
    // Only install listeners once per SortableGroup.
    if (installedElements.length == 1) {
      _logger.finest('first element in this sortable group installed, add listeners');
      // Create placeholder on dragStart (only possible when drag starts in a sortable)
      _dragStartSub = onDragStart.listen((DraggableEvent event) {
        _logger.finest('onDragStart');
        
        _currentPlaceholder = new _Placeholder(event.draggable, currentDraggableGroup);
      });
      
      // Show placeholder when an item of this group is entered.
      _dragEnterSub = _dropzoneGroup.onDragEnter.listen((DropzoneEvent event) {
        _logger.finest('onDragEnter');
        
        // Test if there already is a placeholder.
        if (_currentPlaceholder == null) {
          _currentPlaceholder = new _Placeholder(event.draggable, 
              currentDraggableGroup);
        }
        
        // Show a placeholder for the entered dropzone.
        _currentPlaceholder.showPlaceholder(event.dropzone, this);
      });
    }
  }
  
  /**
   * Uninstalls sortable behaviour on [element] and removes it from this group.
   * All [StreamSubscription]s that were added with install are canceled.
   */
  void uninstall(Element element) {
    _logger.finest('uninstalling sortable');
    super.uninstall(element);
      
    _dropzoneGroup.uninstall(element);
      
    if (installedElements.isEmpty) {
      _logger.finest('last element in this sortable group uninstalled, cancel group subscriptions');
      // Last sortable of this group was uninstalled --> cancel subscriptions.
      _dragEnterSub.cancel();
      _dragEnterSub = null;
      _dragStartSub.cancel();
      _dragStartSub = null;
    }
  }
}

/**
 * Defines a position of an element in its [parent].
 */
class Position {
  Element parent;
  int index;
  
  Position(this.parent, this.index);
  
  /**
   * Inserts the specified [element] as a child of [parent] at [index].
   */
  void insert(Element element) {
    parent.children.insert(index, element);
  }

  @override
  int get hashCode {
    int result = 17;
    result = 37 * result + parent.hashCode;
    result = 37 * result + index.hashCode;
    return result;
  }

  @override
  bool operator ==(other) {
    if (identical(other, this)) return true;
    return (other is Position
        && other.parent == parent 
        && other.index == index);
  }
}

/**
 * Result used to carry information about a completed sortable Drag and Drop
 * operation. The [draggable] was moved from [originalPosition] to [newPosition].
 *  
 * If the [draggable] was dragged into another group, [newGroup] is different
 * from [originalGroup]. In that case you might want to uninstall from [originalGroup]
 * and install again in [newGroup].
 */
class SortableEvent {
  Element draggable;
  Position originalPosition;
  Position newPosition;
  Group originalGroup;
  Group newGroup;
  
  SortableEvent(this.draggable, this.originalPosition, this.newPosition,
                this.originalGroup, this.newGroup);
}

/**
 * Handles replacing of a dropzone with a placeholder.
 */
class _Placeholder {
  /// The draggable that this placeholder is for.
  final Element draggable;
  
  /// Position of the draggable element before dragging.
  Position originalPosition;
  
  /// Current Position of the placeholder.
  Position newPosition;
  
  /// The group of the draggable element before dragging. 
  /// Might be a [DraggableGroup] or a [SortableGroup].
  DraggableGroup originalGroup;
  
  /// Current group of the placeholder.
  SortableGroup newGroup;
  
  /// The placeholder element.
  Element placeholderElement;
  
  /// Flag to tell whether this dropzone was dropped.
  bool _dropped = false;
  
  StreamSubscription _dropzoneOverSub; 
  StreamSubscription _dropzoneDropSub; 
  StreamSubscription _placeholderDropSub;
  StreamSubscription _placeholderOverSub;
  StreamSubscription _draggableEndSub;
  
  /**
   * Creates a new placeholder for the specified [draggable].
   */
  _Placeholder(this.draggable, this.originalGroup) {
    // Save original position of draggable for later.
    originalPosition = new Position(draggable.parent,
        html5.getElementIndexInParent(draggable));
  }
  
  
  /**
   * Shows the placeholder at the position of [dropzone].
   * 
   * Ensures that there is no flickering (going back and forth between two 
   * states) if the dropzone is bigger than the placeholder. This means that 
   * this method will only show the placeholder for a bigger dropzone if the 
   * mouse is in a safe region of the dropzone.
   */
  void showPlaceholder(Element dropzone, SortableGroup group) {
    _logger.finest('showPlaceholder');
    newGroup = group;
    
    if (placeholderElement == null) {
      _createPlaceholderElement();
    }
    
    if (_isDropzoneHigher(dropzone) 
        || (newGroup.isGrid && _isDropzoneWider(dropzone))) {
      _logger.finest('dropzone is bigger than placeholder, listening to onDragOver events');
      
      // There is already an dragOver subscription on a dropzone --> cancel.
      if (_dropzoneOverSub != null) {
        _dropzoneOverSub.cancel();
      }
      
      // On elements that are bigger than the dropzone we must listen to 
      // dragOver events and determine from the mouse position, whether to 
      // change placeholder position.
      _dropzoneOverSub = dropzone.onDragOver.listen((MouseEvent event) {
        _logger.finest('placeholder (dropzone) onDragOver');
        
        _showPlaceholderForBiggerDropzone(dropzone, event);
      });
      
      if (_dropzoneDropSub != null) {
        _dropzoneDropSub.cancel();
      }
      _dropzoneDropSub = dropzone.onDrop.listen((MouseEvent event) {
        _logger.finest('placeholder (dropzone) onDrop');
        _dropped = true;
      });
      
    } else {
      _logger.finest('dropzone is not bigger than placeholder, not listening to onDragOver events');
      
      Position dropzonePosition = new Position(dropzone.parent,
          html5.getElementIndexInParent(dropzone));
      _doShowPlaceholder(dropzone, dropzonePosition);
    }
  }
  
  /**
   * Hides the placeholder and shows the draggable.
   * If [revertToOriginal] is true, the draggable is shown at the 
   * [originalPosition]. If false, it is shown at the current [newPosition].
   */
  void hidePlaceholder({bool revertToOriginal: false}) {
    placeholderElement.remove();
    
    if (revertToOriginal) {
      originalPosition.insert(draggable);      
    } else {
      newPosition.insert(draggable);
      
      // Fire sort event
      if (newPosition != originalPosition) {
        _logger.finest('firing onSortableComplete event');
        
        if (newGroup._onSortUpdate != null) {
          newGroup._onSortUpdate.add(new SortableEvent(draggable, 
              originalPosition, newPosition, originalGroup, newGroup));
        }
      }
    }
  }
  
  /**
   * Creates the [placeholderElement].
   */
  void _createPlaceholderElement() {
    _logger.finest('creating new placeholder');
    placeholderElement = new Element.tag(draggable.tagName);
    
    if (newGroup.placeholderClass != null) {
      placeholderElement.classes.add(newGroup.placeholderClass);
    }
    
    if (newGroup.forcePlaceholderSize) {
      // Placeholder receives the computed size from the dragged element.
      placeholderElement.style.height = draggable.getComputedStyle().height; 
      placeholderElement.style.width = draggable.getComputedStyle().width;
    }
    
    // Listen for drops inside placeholder.
    _placeholderDropSub = placeholderElement.onDrop.listen((_) {
      _logger.finest('placeholder onDrop');
      _dropped = true;
    });
    
    // Allow us to drop by preventing default.
    _placeholderOverSub = placeholderElement.onDragOver.listen((MouseEvent mouseEvent) {
      // Take drop effect from old group where the drag was started because it 
      // must match the effectAllowed property in the dragStart event
      mouseEvent.dataTransfer.dropEffect = originalGroup.dropEffect;
      // This is necessary to allow us to drop.
      mouseEvent.preventDefault();
    });
    
    // Hide placeholder on dragEnd of draggable.
    _draggableEndSub = draggable.onDragEnd.listen((MouseEvent event) {
      _logger.finest('placeholder onDragEnd');
      if (_dropped) {
        _logger.finest('placeholder was dropped -> Show draggable at new position');
        // Hide placeholder and show draggable again at new position.
        _currentPlaceholder.hidePlaceholder();
      } else {
        // Not dropped. This means the drag ended outside of a placeholder or
        // the drag was cancelled somehow (ESC-key, ...)
        // Revert to state before dragging.
        _logger.finest('placeholder not dropped -> Revert to state before dragging');
        _currentPlaceholder.hidePlaceholder(revertToOriginal: true);
      }
      
      // Reset current placeholder.
      _currentPlaceholder = null;
      
      // Cancel all subscriptions.
      if (_dropzoneOverSub != null) {
        _dropzoneOverSub.cancel();
      }
      if (_dropzoneDropSub != null) {
        _dropzoneDropSub.cancel();
      }
      _placeholderDropSub.cancel();
      _placeholderOverSub.cancel();
      _draggableEndSub.cancel();
    });
  }
  
  /**
   * Shows the placeholder at the position of [dropzone] ONLY if mouse is not
   * in the disabled region of the bigger [dropzone].
   */
  void _showPlaceholderForBiggerDropzone(Element dropzone, 
                                        MouseEvent event) {
    Position dropzonePosition = new Position(dropzone.parent,
        html5.getElementIndexInParent(dropzone));
    
    if (_isDropzoneHigher(dropzone)) {
      if (_isInDisabledVerticalRegion(dropzone, dropzonePosition, event)) {
        return;
      }
    }
    
    if (newGroup.isGrid) {
      if (_isDropzoneWider(dropzone)) {
        if (_isInDisabledHorizontalRegion(dropzone, dropzonePosition, event)) {
          return; 
        }
      }
    }
    _logger.finest('showing placeholder for bigger dropzone');
    _doShowPlaceholder(dropzone, dropzonePosition);
  }
  
  /**
   * Actually shows the placeholder (with no further checks).
   */
  void _doShowPlaceholder(Element dropzone, Position dropzonePosition) {
    // Show placeholder at the position of dropzone.
    newPosition = dropzonePosition;
    _logger.finest('showing placeholder at index ${newPosition.index}');
    placeholderElement.remove(); // Might already be at a different position.
    newPosition.insert(placeholderElement);
    
    // Make sure the draggable element is removed.
    draggable.remove();
    
    // When placeholder is shown, we clear the drag over elements so 
    // we have a fresh start of the counter whenever any other element is entered.
    _logger.finest('clearing dragOverElements {dragOverElements.length before clearing: ${currentDragOverElements.length}}');
    Timer.run(() => currentDragOverElements.clear());
  }
  
  /**
   * Returns true if the [dropzone]'s height is greater than this placeholder's.
   * If the placeholder hasn't been added and thus has a size of 0, false is
   * returned.
   */
  bool _isDropzoneHigher(Element dropzone) {
    return placeholderElement.clientHeight > 0 
        && dropzone.clientHeight > placeholderElement.clientHeight;
  }
  
  /**
   * Returns true if the [dropzone]'s width is greater than this placeholder's.
   * If the placeholder hasn't been added and thus has a size of 0, false is
   * returned.
   */
  bool _isDropzoneWider(Element dropzone) {
    return placeholderElement.clientWidth > 0 
        && dropzone.clientWidth > placeholderElement.clientWidth;
  }
  
  /**
   * Returns true if the mouse is in the disabled vertical region of the 
   * dropzone.
   */
  bool _isInDisabledVerticalRegion(Element dropzone, Position dropzonePosition, 
                                   MouseEvent event) {
    if (newPosition != null 
        && newPosition.parent == dropzonePosition.parent
        && newPosition.index > dropzonePosition.index) {
      // Current placeholder position is after the new dropzone position.
      // --> Disabled region is in the bottom part of the dropzone.
      
      // Calc the mouse position relative to the dropzone.
      num mouseRelativeTop = event.page.y - css.getTopOffset(dropzone);  
      if (mouseRelativeTop > placeholderElement.clientHeight) {
        return true; // In disabled region.
      }
    }
    return false;
  }
  
  /**
   * Returns true if the mouse is in the disabled horizontal region of the 
   * dropzone. This check is only necessary for grids.
   */
  bool _isInDisabledHorizontalRegion(Element dropzone, Position dropzonePosition, 
                                     MouseEvent event) {
    // Calc the mouse position relative to the dropzone.
    num mouseRelativeLeft = event.page.x - css.getLeftOffset(dropzone);      
    
    if (newPosition != null 
        && newPosition.parent == dropzonePosition.parent) {
      
      if (newPosition.index > dropzonePosition.index) {
        // Current placeholder position is after the new dropzone position (with 
        // same parent) --> Disabled region is in the right part of the dropzone.
        if (mouseRelativeLeft > placeholderElement.clientWidth) {
          return true; // In disabled region.
        }
      }
      if (newPosition.index < dropzonePosition.index) {
        // Current placeholder position is after the new dropzone position.
        // --> Disabled region is in the left part of the dropzone.
        if (mouseRelativeLeft < placeholderElement.clientWidth) {
          return true; // In disabled region.
        }
      }
    }
    return false;
  }
}
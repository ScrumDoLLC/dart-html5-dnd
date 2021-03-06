library html5_dnd_example;

import 'dart:html';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:html5_dnd/html5_dnd.dart';

main() {
  // Uncomment to enable logging.
  initLogging();
  
  // Install Drag and Drop examples.
  sectionDraggableAndDropzone();
  sectionDraggingDivs();
  sectionDropEffects();
  sectionDragImages();
  sectionNestedElements();
  
  // Install Sortable examples.
  sectionSortableList();
  sectionSortableGrid();
  sectionSortableListHandles();
  sectionCancelDrag();
  sectionSortableTwoGroups();

  // Used for the code examples on the blog website.
//  _installCodeblockTabs();
}

initLogging() {
  DateFormat dateFormat = new DateFormat('yyyy.mm.dd HH:mm:ss.SSS');
  
  // Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${dateFormat.format(r.time)}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  
  // Root logger level.
  Logger.root.level = Level.FINEST;
}

  
sectionDraggableAndDropzone() {
  // Install draggables (documents).
  DraggableGroup dragGroup = new DraggableGroup()
  ..installAll(querySelectorAll('#draggable-dropzone .document'));
  
  // Install dropzone (trash).
  DropzoneGroup dropGroup = new DropzoneGroup()
  ..install(querySelector('#draggable-dropzone .trash'))
  ..accept.add(dragGroup)
  ..onDrop.listen((DropzoneEvent event) {
    event.draggable.remove();
    event.dropzone.classes.add('full');
  });
}

sectionDraggingDivs() {
  // Install draggable.
  DraggableGroup dragGroup = new DraggableGroup()
  ..install(querySelector('#dragging-divs .dragme'));
  
  // Install dropzone.
  DropzoneGroup dropGroup = new DropzoneGroup()
  ..install(querySelector('#dragging-divs .dropzone'))
  ..accept.add(dragGroup);
}

sectionDropEffects() {
  // Install draggables.
  DraggableGroup dragGroupMove = new DraggableGroup()
  ..dropEffect = DROP_EFFECT_MOVE
  ..install(querySelector('#drop-effects .move'));
  
  DraggableGroup dragGroupCopy = new DraggableGroup()
  ..dropEffect = DROP_EFFECT_COPY
  ..install(querySelector('#drop-effects .copy'));
  
  DraggableGroup dragGroupLink = new DraggableGroup()
  ..dropEffect = DROP_EFFECT_LINK
  ..install(querySelector('#drop-effects .link'));
  
  DraggableGroup dragGroupNone = new DraggableGroup()
  ..dropEffect = DROP_EFFECT_NONE
  ..install(querySelector('#drop-effects .none'));
  
  // Install dropzone.
  DropzoneGroup dropGroup = new DropzoneGroup()
  ..install(querySelector('#drop-effects .trash'))
  ..accept.addAll([dragGroupMove, dragGroupCopy, dragGroupLink, dragGroupNone])
  ..onDrop.listen((DropzoneEvent event) {
    event.draggable.remove();
    event.dropzone.classes.add('full');
  });
}

sectionDragImages() {
  ImageElement png = new ImageElement(src: 'icons/smiley-happy.png');
  CanvasElement canvas = new CanvasElement();
  var ctx = canvas.context2D
      ..fillStyle = "rgb(200,0,0)"
      ..fillRect(10, 10, 55, 50);
  var dataUrl = canvas.toDataUrl("image/jpeg", 0.95);
  //Create a new image element from the data URL.
  ImageElement canvasImage = new ImageElement(src: dataUrl);
  
  // Install draggables.
  DraggableGroup dragGroupOne = new DraggableGroup(
      dragImageFunction: (Element draggable) => new DragImage(png, 40, 40))
  ..install(querySelector('#drag-images .one'));
  
  DraggableGroup dragGroupTwo = new DraggableGroup(
      dragImageFunction: (Element draggable) => new DragImage(png, -20, -20))
  ..install(querySelector('#drag-images .two'));
  
  DraggableGroup dragGroupThree = new DraggableGroup(
      dragImageFunction: (Element draggable) => new DragImage(canvasImage, 20, 20))
  ..install(querySelector('#drag-images .three'));
  
  // Install dropzone.
  DropzoneGroup dropGroup = new DropzoneGroup()
  ..install(querySelector('#drag-images .dropzone'))
  ..accept.addAll([dragGroupOne, dragGroupTwo, dragGroupThree]);
}

sectionNestedElements() {
  TextAreaElement textarea = querySelector('#nested-elements .dropzone textarea');
  InputElement input = querySelector('#nested-elements .dropzone input');
  input.value = 'Drag here!';
  textarea.text = '';
  int enterLeaveCounter = 1;
  int overCounter = 1;
  
  // Install draggables.
  DraggableGroup dragGroup = new DraggableGroup()
  ..install(querySelector('#nested-elements .dragme'));
  
  // Install dropzone.
  DropzoneGroup dropGroup = new DropzoneGroup()
  ..install(querySelector('#nested-elements .dropzone'))
  ..accept.add(dragGroup)
  ..onDragEnter.listen((DropzoneEvent event) {
    textarea.appendText('${enterLeaveCounter++} drag enter fired\n');
    textarea.scrollTop = textarea.scrollHeight;
  })
  ..onDragOver.listen((DropzoneEvent event) {
    input.value = '${overCounter++} drag over fired';
  })
  ..onDragLeave.listen((DropzoneEvent event) {
    textarea.appendText('${enterLeaveCounter++} drag leave fired\n');
    textarea.scrollTop = textarea.scrollHeight;
  })
  ..onDrop.listen((DropzoneEvent event) {
    textarea.appendText('${enterLeaveCounter++} drop fired\n');
    textarea.scrollTop = textarea.scrollHeight;
  });
}

sectionSortableList() {
  SortableGroup sortGroup = new SortableGroup()
  ..installAll(querySelectorAll('#sortable-list li'))
  ..onSortUpdate.listen((SortableEvent event) {
    // do something when user sorted the elements...
  });
  
  // Only accept elements from this section.
  sortGroup.accept.add(sortGroup);
}

sectionSortableGrid() {
  SortableGroup sortGroup = new SortableGroup()
  ..isGrid = true
  ..installAll(querySelectorAll('#sortable-grid li'));
  
  // Only accept elements from this section.
  sortGroup.accept.add(sortGroup);
}

sectionSortableListHandles() {
  SortableGroup sortGroup = new SortableGroup(handle: 'span')
  ..installAll(querySelectorAll('#sortable-list-handles li'));
  
  // Only accept elements from this section.
  sortGroup.accept.add(sortGroup);
}

sectionCancelDrag() {
  // Install draggable.
  DraggableGroup dragGroup = new DraggableGroup(
      cancel: 'textarea, button, .nodrag')
  ..install(querySelector('#cancel-drag .dragme'));
}

sectionSortableTwoGroups() {
  ImageElement png = new ImageElement(src: 'icons/smiley-happy.png');
  
  SortableGroup sortGroup1 = new SortableGroup()
  ..installAll(querySelectorAll('#sortable-two-groups .group1 li'))
  ..onSortUpdate.listen((SortableEvent event) {
    event.originalGroup.uninstall(event.draggable);
    event.newGroup.install(event.draggable);
  });
  
  SortableGroup sortGroup2 = new SortableGroup(
      dragImageFunction: (Element draggable) => new DragImage(png, 5, 5))
  ..installAll(querySelectorAll('#sortable-two-groups .group2 li'))
  ..onSortUpdate.listen((SortableEvent event) {
    if (event.originalGroup != event.newGroup) {
      event.originalGroup.uninstall(event.draggable);
      event.newGroup.install(event.draggable);
    }
  });
  
  // Only accept elements from this section.
  sortGroup1.accept.addAll([sortGroup1, sortGroup2]);
  sortGroup2.accept.addAll([sortGroup1, sortGroup2]);
}


_installCodeblockTabs() {
  List<AnchorElement> tabLinks = querySelectorAll('.example-code .menu li a');
  for (AnchorElement link in tabLinks) {
    link.onClick.listen((MouseEvent event) {
      event.preventDefault();
      
      Element exampleCodeParent = link.parent.parent.parent;
      
      // Remove active class on all menu and content tabs.
      exampleCodeParent.querySelectorAll('[tab]').forEach((Element e) {
        e.classes.remove('active');
      });

      // Add active class.
      String currentTab = link.attributes['tab'];
      link.classes.add('active');
      exampleCodeParent.querySelector('.content [tab="$currentTab"]').classes.add('active');
    });  
  }
}
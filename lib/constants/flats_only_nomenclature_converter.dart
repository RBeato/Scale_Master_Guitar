String flatsOnlyNoteNomenclature(String noteSubString) {
  // print('Called flatsOnlyNoteNomenclature');
  switch (noteSubString) {
    case 'C♭':
      noteSubString = 'B';
      break;
    case 'C♯':
      noteSubString = 'D♭';
      break;
    case 'D𝄫':
      noteSubString = 'C';
      break;
    case 'D♯':
      noteSubString = 'E♭';
      break;
    case 'E𝄫':
      noteSubString = 'D';
      break;
    case 'F♭':
      noteSubString = 'E';
      break;
    case 'F♯':
      noteSubString = 'G♭';
      break;
    case 'G𝄫':
      noteSubString = 'F';
      break;
    case 'G♯':
      noteSubString = 'A♭';
      break;
    case 'A𝄫':
      noteSubString = 'G';
      break;
    case 'A♯':
      noteSubString = 'B♭';
      break;
    case 'B𝄫':
      noteSubString = 'A';
      break;
  }

  return noteSubString;
}

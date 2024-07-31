flatsToSharpsNomenclature(noteSubString) {
  switch (noteSubString) {
    case 'C♭':
      noteSubString = 'B';
      break;
    case 'D♭':
      noteSubString = 'C♯';
      break;
    case 'D𝄫':
      noteSubString = 'C';
      break;
    case 'E♭':
      noteSubString = 'D♯';
      break;
    case 'E𝄫':
      noteSubString = 'D';
      break;
    case 'F♭':
      noteSubString = 'E';
      break;
    case 'G♭':
      noteSubString = 'F♯';
      break;
    case 'G𝄫':
      noteSubString = 'F';
      break;
    case 'A♭':
      noteSubString = 'G♯';
      break;
    case 'A𝄫':
      noteSubString = 'G';
      break;
    case 'B♭':
      noteSubString = 'A♯';
      break;
    case 'B𝄫':
      noteSubString = 'A';
      break;
  }

  return noteSubString;
}

#landuse_label_gen[type='forest'][zoom=12],
#landuse_label_gen[type='park'][zoom=12],
#landuse_label_gen[type='residential'][zoom=12],
#landuse_label_gen[type='commercial'][zoom=12],
#landuse_label_gen[type='industrial'][zoom=12],
#landuse_label_gen[type='retail'][zoom=12],
#landuse_label_gen[type='wood'][zoom=12],
#landuse_label_gen[zoom>=13][zoom<15],
#landuse_label[zoom>=15][area>50000],
#landuse_label[zoom>=17] {
  text-name: '[name]';
  [lang='fr'] {
    text-name: '[name].replace("Saint-", "St-").replace("Sainte-", "Ste-")';
  }
  text-face-name: @light;
  [type='commercial'],[type='industrial'],[type='retail'] {
    text-face-name: @medium;
  }
  text-placement: point;
  text-fill: @landuse_text;
  text-size: 11;
  text-margin: 20;
  text-halo-fill: @halo;
  text-halo-radius: 2;
  text-wrap-width: 40;
  text-label-position-tolerance: 20;
  text-character-spacing: 0.1;
  text-line-spacing: -2;
  [zoom>=14] {
    text-size: 12;
  }
}

#openaddresses[zoom>=17][zoom<18][mod5=true],
#openaddresses[zoom>=18],
#housenumber[zoom>=17][zoom<19][mod5=true],
#housenumber[zoom>=19] {
  text-name: '[housenumber]';
  text-placement: interior;
  text-face-name: @regular;
  text-fill: @road_text;
  text-halo-fill: @halo;
  text-halo-radius: 1;
  text-size: 8;
  text-margin: 5;
  [zoom>=18] {
    text-size: 9;
  }
}

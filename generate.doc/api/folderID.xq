module namespace ivgpu = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/загрузкаРПД';

import module namespace upload = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/загрузкаРПД'
  at '../RPD/generate.RPD.upload.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/generate/rpd/{ $ID }/folder.id/{ $storeID }' )
  %rest:method( 'GET' )
  %output:method( 'text' )
function ivgpu:идентификаторПапкиРПД( $ID, $storeID ){
  serialize(
    <csv>
      <record><folderID>{  upload:getFolderIDbyFileID( $storeID,  $ID ) }</folderID></record>
    </csv>,
    map {
      'method': 'csv',
      'csv': map { 'header': 'yes', 'separator': ',' }
    }
  )
};
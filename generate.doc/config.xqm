module namespace config = '/sandbox/ivgpu/api/v01/generate/config';

declare variable $config:filePath := 'config.xml';

declare function config:param( $params ){
  let $file := doc( $config:filePath )
  return
    $file/config/param[ @id = $params ]/text()
};
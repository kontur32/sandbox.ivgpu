module namespace config = '/sandbox/ivgpu/api/v01/generate/config';

declare variable $config:filePath := 'config.xml';

declare function config:param( $params ){
  let $file := doc( $config:filePath )
  return
    $file/config/param[ @id = $params ]/text()
};

declare function config:bitrixAPI(){
  'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/'
};
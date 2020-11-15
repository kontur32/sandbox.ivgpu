module namespace config = 'sandbox/ivgpu/вопросник/модули/config';

declare variable $config:configPath := 'config.xml';

declare 
  %public
function config:param( $param as xs:string )
  as xs:string
{
  let $conf := 
    doc( $config:configPath )
  return
    $conf/params/param[ @id = $param ]/text()
};
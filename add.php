<?php

if ($_GET["secret"] == 'test') {
        file_put_contents("/path/to/access.log", date("Y-m-d H:i:s") . "\t" . $_GET["log"] . "\n", FILE_APPEND);
        echo "ok";
} else {
        echo "fail";
}

?>

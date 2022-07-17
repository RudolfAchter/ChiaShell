#Not Using ChiaShell for now but chia native CLI

$nfts=@(
#@{ id="nft1lmcppuusuyx307q5vgfu888pvkq8vl5slqglr0keu9pzxu98jz7sf5avy8"; name="wood_club_07"}
#@{ id="nft13706qfmk8hrq5wjchzz6q20g0w0ee8lm07lw7cw7sha7zmz9fwds86z3m2"; name="short_axe_07"}
#@{ id="nft1tz2gc3pgterfgf6e3ndqrnqtls9gutlntmy2xfy6809letxz7eeqxhjz54"; name="sword_07"}
@{ id="nft1pfcmhr0grkfxkqwwthlmnltusysqrtdkwz8a0g7zywkjfu4wxdssuy2j2a"; name="knife_17"}
@{ id="nft1vsa8va3at40pvqdvsnqpz0k75aavtflsyqs3rfvm7zyp9aqavgtqfsj90s"; name="short_bow_07"}
@{ id="nft1myhjwpkhle7hu49u06u37tgy8c346xrrktvm8nt2evdwsdt2fq9swhjpxf"; name="khopesh_09"}
@{ id="nft1d74txv3uesxxvmdxfm59e9u6r888es0xsenk62zpc4s7neh605qsv50hp2"; name="khopesh_20"}
@{ id="nft1976rcjsjys3yex4y5lf565k9ex6t9mjtvm4ddxldp6wj0q0gj9jsw3yv7g"; name="khopesh_08"}
@{ id="nft1mkxnhth6f06trdfmeq04mghy0d6jau4jgtze9ahl5z3zzlfaa79ssmtdk2"; name="khopesh_10"}
@{ id="nft179zvlehmgq6d8nprncp8mey4nvkunk5lpj72gd46749y92hm3tkqlvwxkj"; name="khopesh_19"}
)

$nfts  | ForEach-Object {
    $nft=$_
    Invoke-ChiaSplitCoins -myAddress xch142lv6v7ecf4d783eahyamw606ympydlx06025f6v3ypcxlu4qp0qwjsm7r -AmountXch 0.04
    chia wallet make_offer --offer "1:0.03" --request ($nft.id +":1") -p ("request_" + $nft.name + ".offer")
}


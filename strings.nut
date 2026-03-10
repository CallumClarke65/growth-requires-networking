function GoalTown::TownBoxText(growth_enabled, text_mode, redraw=false)
{
    local text_townbox = null;

    /*
    // If the function is called with false, town is not growing. Give a help message.
    local display_cargo = true;
    if (!growth_enabled || 0 == text_mode) {
        if (display_cargo) {
            text_townbox = GSText(GSText["STR_TOWNBOX_CARGO_"+(::CargoCatNum-1)]);
            text_townbox = this.TownTextContributor(text_townbox);

            local cargo_mask = 0;
            foreach (cargo in ::CargoLimiter) {
                cargo_mask = cargo_mask | 1 << cargo;
            }
            text_townbox.AddParam(GSText(GSText.STR_TOWNBOX_NOGROWTH, cargo_mask));

            foreach (index, category in this.town_cargo_cat) {
                cargo_mask = 0;
                foreach (cargo in category) {
                    cargo_mask = cargo_mask | 1 << cargo;
                }
                text_townbox.AddParam(GSText(GSText["STR_CARGOCAT_LABEL_"+::CargoCatList[index]]));
                text_townbox.AddParam(cargo_mask);
            }
        } else {
            local cargo_mask = 0;
            foreach (cargo in ::CargoLimiter) {
                cargo_mask = cargo_mask | 1 << cargo;
            }
            text_townbox = GSText(GSText.STR_TOWNBOX_NOGROWTH, cargo_mask);
        }
        return text_townbox;
    }

    switch (text_mode) {
        case 1: // automatic
            if (::SettingsTable.randomization == Randomization.NONE) {
                text_townbox = this.TownTextCategories();
                break;
            } else if (::SettingsTable.randomization == Randomization.INDUSTRY_DESC
                    || ::SettingsTable.randomization == Randomization.INDUSTRY_ASC) {
                text_townbox = this.TownTextCategoriesCombined(display_cargo);
                break;
            }

            if (!redraw) {
                this.town_text_scroll = (this.town_text_scroll < 1) ? this.town_text_scroll + 1 : 0;
            }
            if (this.town_text_scroll > 0) {
                text_townbox = this.TownTextCargos(display_cargo);
            } else {
                text_townbox = this.TownTextCategories();
            }
            break;
        case 2: // categories
            text_townbox = this.TownTextCategories();
            break;
        case 3: // cargos
            text_townbox = this.TownTextCargos(display_cargo);
            break;
        case 4: // combined
            text_townbox = this.TownTextCategoriesCombined(display_cargo);
            break;
        case 5: // all cargos
            text_townbox = this.TownTextCargos(true);
            break;
    }
    */

    return text_townbox;
}

function GoalTown::TownTextLimiter(text_townbox, category)
{
    local str = category ? "CATEGORY" : "CARGO";

    if (this.allowGrowth && this.limit_delay > 0 && this.limit_transported != 0) {
        text_townbox.AddParam(GSText(GSText["STR_TOWNBOX_" + str + "_DELAYED"], this.limit_transported));
    }
    else if (this.allowGrowth && this.limit_transported != 0) {
        text_townbox.AddParam(GSText(GSText["STR_TOWNBOX_" + str + "_LOW"], this.limit_transported));
    }
    else if (!this.allowGrowth) {
        text_townbox.AddParam(GSText(GSText["STR_TOWNBOX_" + str + "_STOP"], this.limit_transported));
    }
    else {
        text_townbox.AddParam(GSText(GSText["STR_TOWNBOX_" + str], GSText(GSText.STR_EMPTY)));
    }

    return text_townbox;
}

function GoalTown::TownTextContributor(text_townbox)
{
    if (this.contributor < 0) {
        text_townbox.AddParam(GSText(GSText.STR_TOWNBOX_NO_CONTRIBUTOR, this.max_population, GSText(GSText.STR_EMPTY)));
    }
    else {
        text_townbox.AddParam(GSText(GSText.STR_TOWNBOX_CONTRIBUTOR, this.max_population, this.contributor));
    }

    return text_townbox;
}


/* Function which builds town texts.
 * Town text will look like below:
 * Cargocat label: required/last supplied/stockpiled
 */
function GoalTown::TownTextCategories()
{
    local max_cat = 0;
    while (max_cat <::CargoCatNum - 1) {
        if (this.town_goals_cat[max_cat + 1] == 0) break;
        max_cat++;
    }

    local text_townbox = GSText(GSText["STR_TOWNBOX_CATEGORY_" + max_cat]);
    text_townbox = this.TownTextContributor(text_townbox);
    text_townbox = this.TownTextLimiter(text_townbox, true);

    for (local i = 0; i <= max_cat; i++) {
        text_townbox.AddParam(GSText(GSText["STR_CARGOCAT_LABEL_" + ::CargoCatList[i]]));
        text_townbox.AddParam(this.town_supplied_cat[i] + " / " + this.town_goals_cat[i]);
    }

    return text_townbox;
}

function GoalTown::TownTextCategoriesCombined(display_all)
{
    local max_cat = 0;
    if (display_all) {
        max_cat = ::CargoCatNum-1;
    } else {
        while (max_cat < ::CargoCatNum-1) {
            if (this.town_goals_cat[max_cat + 1] == 0) break;
            max_cat++;
        }
    }

    local text_townbox = GSText(GSText["STR_TOWNBOX_COMBINED_" + max_cat]);
    text_townbox = this.TownTextContributor(text_townbox);
    text_townbox = this.TownTextLimiter(text_townbox, true);

    for (local index = 0; index <= max_cat; ++index) {
        local cargo_mask = 0;
        foreach (cargo in this.town_cargo_cat[index]) {
            cargo_mask += 1 << cargo;
        }
        text_townbox.AddParam(cargo_mask);
        text_townbox.AddParam(this.town_supplied_cat[index] + " / " + this.town_goals_cat[index]);
    }

    return text_townbox;
}

function GoalTown::TownTextCargos(display_all)
{
    local max_cat = 0;
    if (display_all) {
        max_cat = ::CargoCatNum-1;
    } else {
        while (max_cat < ::CargoCatNum-1) {
            if (this.town_goals_cat[max_cat+1] == 0) break;
            max_cat++;
        }
    }

    local text_townbox = GSText(GSText["STR_TOWNBOX_CARGO_" + max_cat]);
    text_townbox = this.TownTextContributor(text_townbox);
    text_townbox = this.TownTextLimiter(text_townbox, false);

    for (local index = 0; index <= max_cat; ++index) {
        local cargo_mask = 0;
        foreach (cargo in this.town_cargo_cat[index]) {
            cargo_mask += 1 << cargo;
        }
        text_townbox.AddParam(GSText(GSText["STR_CARGOCAT_LABEL_" + ::CargoCatList[index]]));
        text_townbox.AddParam(cargo_mask);
    }

    return text_townbox;
}

/* Building the text for towns' signtexts. */
function GoalTown::TownSignText()
{
    local text_townsign = null;
    if (GSTown.GetGrowthRate(this.id) > 880) {
        text_townsign = GSText(GSText.STR_TOWNSIGN_NOTGROWING);
    } else {
        local growth_rate = GSTown.GetGrowthRate(this.id);
        if (::SettingsTable.wallclock_timekeeping == 1) { // Wallclock Timekeeping
            if (growth_rate > 300)
                text_townsign = GSText(GSText.STR_TOWNSIGN_GROWTHRATE, GSTown.GetGrowthRate(this.id) / 30, GSText(GSText.STR_TOWNSIGN_MINUTES));
            else
                text_townsign = GSText(GSText.STR_TOWNSIGN_GROWTHRATE, GSTown.GetGrowthRate(this.id) * 2, GSText(GSText.STR_TOWNSIGN_SECONDS));
        } else {
            if (growth_rate > 360)
                text_townsign = GSText(GSText.STR_TOWNSIGN_GROWTHRATE, GSTown.GetGrowthRate(this.id) / 30, GSText(GSText.STR_TOWNSIGN_MONTHS));
            else
                text_townsign = GSText(GSText.STR_TOWNSIGN_GROWTHRATE, GSTown.GetGrowthRate(this.id), GSText(GSText.STR_TOWNSIGN_DAYS));
        }
    }
    return text_townsign;
}
